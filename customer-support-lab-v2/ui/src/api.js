export async function request(path, { optional = false, ...options } = {}) {
  const response = await fetch(path, {
    ...options,
    signal: AbortSignal.timeout(15000),
    headers: { "Content-Type": "application/json", ...options.headers },
  });
  if (optional && response.status === 404) return null;
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = null;
  }
  if (!response.ok) {
    const fallback =
      response.status === 409
        ? "The ticket changed or this action conflicts with an existing review. Refresh before reviewing again."
        : `Request failed (HTTP ${response.status}).`;
    throw new Error(data?.detail || data?.message || fallback);
  }
  return { data, readPath: response.headers.get("X-Read-Path") };
}

export const post = (path, data, options = {}) =>
  request(path, { ...options, method: "POST", body: JSON.stringify(data) });
export const formatTime = (value) =>
  value
    ? new Date(value).toLocaleString(undefined, {
        dateStyle: "medium",
        timeStyle: "medium",
      })
    : "—";
export const percentage = (value) => `${(value * 100).toFixed(1)}%`;
export function needsReview(ticket, snapshot) {
  if (ticket.workflowStatus !== "ENRICHED") return false;
  const review = snapshot?.reviewStates.find((r) => r.ticketId === ticket.id);
  return (
    !review ||
    review.decision !== "APPROVED" ||
    new Date(review.generatedAt) > new Date(review.decidedAt)
  );
}
