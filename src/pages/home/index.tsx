import { useCustom } from "@refinedev/core";

import { Col, Row } from "antd";

import type { DashboardTotalCountsQuery } from "@/graphql/types";

import {
  UpcomingEvents,
  DealsChart,
  LatestActivities
  //TotalCountCard,
} from "@/components";
import { DASHBOARD_TOTAL_COUNTS_QUERY } from "@/graphql/queries";

export const Home = () => {
  const {
    query: { isLoading },

    result: data,
  } = useCustom<DashboardTotalCountsQuery>({
    url: ' ',
    method: "get",
    meta: { gqlQuery: DASHBOARD_TOTAL_COUNTS_QUERY },
  });

  return (
    <div className="page-container">

      <Row
        gutter={[32, 32]}
        style={{
          marginTop: "32px",
        }}
      >
        <Col
          xs={24}
          sm={24}
          xl={8}
          style={{
            height: "460px",
          }}
        >
          <UpcomingEvents />
        </Col>
        <Col
          xs={24}
          sm={24}
          xl={16}
          style={{
            height: "460px",
          }}
        >
          <DealsChart />
        </Col>
      </Row>

      <Row
        gutter={[32, 32]}
        style={{
          marginTop: "32px",
        }}
      >
        <Col xs={24}>
          <LatestActivities />
        </Col>
      </Row>
    </div>
  );
};
