import { GraphQLFormattedError } from "graphql";

type Error = {
  message: string;
  statusCode: string;
};

const customFetch = async (url: string, options: RequestInit) => {
  const accessToken = localStorage.getItem("access_token");

  const headers = (options.headers as Record<string, string>) ?? {};

  return await fetch(url, {
    ...options,
    headers: {
      ...headers,
      ...(accessToken
        ? { Authorization: headers.Authorization || `Bearer ${accessToken}` }
        : {}),
      "Content-Type": "application/json",
      "Apollo-Require-Preflight": "true",
    },
  });
};

const getGraphQLErrors = (
  body: Record<"errors", GraphQLFormattedError[] | undefined>,
): Error | null => {
  if (!body) {
    return {
      message: "Unknown error",
      statusCode: "INTERNAL_SERVER_ERROR",
    };
  }

  if ("errors" in body) {
    const errors = body?.errors;

    const messages = errors?.map((error) => error?.message)?.join("");
    const code = errors?.[0]?.extensions?.code;

    return {
      message: messages || JSON.stringify(errors),
      statusCode: code || 500,
    };
  }
  return null;
};

export const fetchWrapper = async (url: string, options: RequestInit) => {
  const response = await customFetch(url, options);

  const responseClone = response.clone();
  let body: Record<string, unknown> | undefined;

  try {
    if (responseClone.headers.get("content-type")?.includes("application/json")) {
      body = await responseClone.json();
    }
  } catch (error) {
    // Swallow JSON parse errors so we can surface HTTP details later.
    body = undefined;
  }

  const error = body ? getGraphQLErrors(body as never) : null;

  if (error) {
    throw error;
  }

  return response;
};
