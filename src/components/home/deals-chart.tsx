import React from "react";

import { useList } from "@refinedev/core";
import type { GetFieldsFromList } from "@refinedev/nestjs-query";

import { DollarOutlined } from "@ant-design/icons";
import { Area, type AreaConfig } from "@ant-design/plots";
import { Card } from "antd";

import { Text } from "../text";
import type { DashboardDealsChartQuery } from "../../graphql/types";

import { DASHBOARD_DEALS_CHART_QUERY } from "../../graphql/queries";
import { mapDealsData } from "../../utilities/helpers";

export const DealsChart = () => {
  const { result: data } = useList<GetFieldsFromList<DashboardDealsChartQuery>>(
    {
      resource: "dealStages",
      filters: [{ field: "title", operator: "in", value: ["WON", "LOST"] }],
      meta: {
        gqlQuery: DASHBOARD_DEALS_CHART_QUERY,
      },
    },
  );

  const dealData = React.useMemo(() => mapDealsData(data?.data), [data?.data]);

  const config = React.useMemo(
    () =>
      ({
        isStack: false,
        data: dealData,
        xField: "timeText",
        yField: "value",
        seriesField: "state",
        animation: true,
        startOnZero: false,
        smooth: true,
        legend: {
          offsetY: -6,
        },
        yAxis: {
          tickCount: 4,
          label: {
            formatter: (value: string) => `$${Number(value) / 1000}k`,
          },
        },
        tooltip: {
          formatter: (datum: { state: string; value: number }) => ({
            name: datum.state,
            value: `$${Number(datum.value) / 1000}k`,
          }),
        },
        areaStyle: ({ state }: { state: string }) => {
          const won = "l(270) 0:#ffffff 0.5:#b7eb8f 1:#52c41a";
          const lost = "l(270) 0:#ffffff 0.5:#f3b7c2 1:#ff4d4f";
          return { fill: state === "Won" ? won : lost };
        },
        color: ({ state }: { state: string }) =>
          state === "Won" ? "#52C41A" : "#F5222D",
      }) as AreaConfig,
    [dealData],
  );

  return (
    <Card
      style={{ height: "100%" }}
      styles={{
        header: { padding: "8px 16px" },
        body: { padding: "24px 24px 0px 24px" },
      }}
      title={
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
          }}
        >
          <DollarOutlined />
          <Text size="sm" style={{ marginLeft: ".5rem" }}>
            Deals
          </Text>
        </div>
      }
    >
      <Area {...config} height={325} />
    </Card>
  );
};

export default DealsChart;
