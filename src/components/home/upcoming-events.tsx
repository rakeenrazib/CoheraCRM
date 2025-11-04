import { useList } from "@refinedev/core";
import type { GetFieldsFromList } from "@refinedev/nestjs-query";

import { CalendarOutlined } from "@ant-design/icons";
import { Badge, Card, List, Skeleton as AntdSkeleton } from "antd";
import dayjs from "dayjs";

import { Text } from "../text";
import type { DashboardCalendarUpcomingEventsQuery } from "../../graphql/types";

import { DASHBOARD_CALENDAR_UPCOMING_EVENTS_QUERY } from "../../graphql/queries";

export const UpcomingEvents = () => {
  const {
    result: data,
    query: { isLoading },
  } = useList<GetFieldsFromList<DashboardCalendarUpcomingEventsQuery>>({
    resource: "events",
    pagination: {
      pageSize: 5,
    },
    sorters: [
      {
        field: "startDate",
        order: "asc",
      },
    ],
    filters: [
      {
        field: "startDate",
        operator: "gte",
        value: dayjs().format("YYYY-MM-DD"),
      },
    ],
    meta: {
      gqlQuery: DASHBOARD_CALENDAR_UPCOMING_EVENTS_QUERY,
    },
  });

  const events = data?.data ?? [];

  return (
    <Card
      style={{
        height: "100%",
      }}
      styles={{
        header: { padding: "8px 16px" },
        body: { padding: "0 1rem" },
      }}
      title={
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
          }}
        >
          <CalendarOutlined />
          <Text size="sm" style={{ marginLeft: ".7rem" }}>
            Upcoming events
          </Text>
        </div>
      }
    >
      {isLoading ? (
        <List
          itemLayout="horizontal"
          dataSource={Array.from({ length: 5 }).map((_, index) => ({
            id: index,
          }))}
          renderItem={() => {
            return (
              <List.Item>
                <List.Item.Meta
                  avatar={<Badge color="transparent" />}
                  title={
                    <AntdSkeleton.Button
                      active
                      style={{
                        height: "14px",
                      }}
                    />
                  }
                  description={
                    <AntdSkeleton.Button
                      active
                      style={{
                        width: "300px",
                        marginTop: "8px",
                        height: "16px",
                      }}
                    />
                  }
                />
              </List.Item>
            );
          }}
        />
      ) : (
        <List
          itemLayout="horizontal"
          dataSource={events}
          renderItem={(item) => {
            const renderDate = () => {
              if (!item?.startDate || !item?.endDate) {
                return "";
              }

              const start = dayjs(item.startDate).format(
                "MMM DD, YYYY - HH:mm",
              );
              const end = dayjs(item.endDate).format("MMM DD, YYYY - HH:mm");

              return `${start} - ${end}`;
            };

            return (
              <List.Item>
                <List.Item.Meta
                  avatar={<Badge color={item?.color || "#d9d9d9"} />}
                  title={<Text size="xs">{renderDate()}</Text>}
                  description={
                    <Text ellipsis={{ tooltip: true }} strong>
                      {item?.title ?? "Untitled event"}
                    </Text>
                  }
                />
              </List.Item>
            );
          }}
        />
      )}

      {!isLoading && events.length === 0 && <NoEvent />}
    </Card>
  );
};

const NoEvent = () => (
  <span
    style={{
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      height: "220px",
    }}
  >
    No upcoming event
  </span>
);

export default UpcomingEvents;
