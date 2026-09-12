# CIVILPEDIA V1-R07 — STAFF / ADMIN OPERATIONS FOUNDATION

PHASE: V1-R07
TITLE: Staff / Admin Operations Foundation
CONTRACT: V1-R07-CONTRACT-v1
STATUS: FROZEN
IMPLEMENTATION_AUTHORIZED: YES

This document is the authoritative requirements source for V1-R07. It freezes
the smallest production-grade internal operations foundation required to run
the existing business-application lifecycle. It does not record implementation
results.

## 1. Phase Goal and Delivery Split

V1-R07 provides an authorized staff application queue and review workspace for
the existing business-application lifecycle. Server permissions remain the
authority. The phase must not expand into a general administration platform.

Delivery order is mandatory:

1. **PART 1 — Codex:** additive server/security migration and focused server tests.
2. **PART 2 — Big Pickle/Kimi:** Flutter projections, gateway reads, providers,
   routes, screens, and focused tests.

Part 2 must not begin until Part 1 is complete and reviewed.

## 2. Host Surface and Routes

V1-R07 uses the existing Flutter application and codebase. It must not create a
separate Flutter application, admin application, or web target.

The canonical staff routes are:

- `/staff/applications`
- `/staff/applications/:applicationId`

They live outside `AppShell` and outside the normal five-tab engineer
navigation. An authorized User Area entry may expose the staff surface, but
entry visibility is only a UX aid and never grants authority.

## 3. Canonical Staff Authority

The canonical human identity is `auth.uid()`.

The only canonical staff authority chain is:

`staff_memberships` → `roles` → `role_permissions` → `permissions.code`

Existing permission helpers and mutation authorization remain canonical. V1-R07
must not introduce authority from auth metadata, `profiles.role_code`, client
flags, hard-coded email addresses, business OWNER/ADMIN roles, or a second staff
identity source. Flutter must never contain or use `service_role` credentials.

Staff membership activity, effective time, and expiry must continue to be
validated server-side. Revoked, inactive, future-effective, and expired
memberships fail closed.

## 4. Staff Membership Provisioning

There is no staff self-enrollment, staff-role management UI, or arbitrary role
editor. Initial staff memberships are provisioned only through a trusted
operational database/Supabase administrative procedure outside the client
application. That procedure must be documented operationally. Flutter must
never create or elevate a staff membership.

## 5. Granular Capability Discovery

PART 1 must add one bounded authenticated RPC that returns the current
session's granular business-application permissions. It derives the caller from
`auth.uid()` and reads the canonical staff permission chain.

The RPC must not return a broad `isAdmin` flag. Flutter may use returned
capabilities to control entry and action visibility, but every queue, detail,
and mutation RPC independently authorizes the caller again. Unknown, malformed,
or unavailable capability state fails closed.

## 6. Staff Read Permission

The additive migration must add:

`business_applications.read`

This permission authorizes staff queue and detail reads. It is assigned to the
existing selected application-review role. V1-R07 does not redesign RBAC.

## 7. Staff Queue RPC

PART 1 must add one bounded staff queue RPC. It requires an authenticated
session and `business_applications.read`. The staff workspace must never receive
direct raw-table SELECT access.

The default actionable statuses are:

- `SUBMITTED`
- `UNDER_REVIEW`
- `CONTACTED`
- `VISIT_SCHEDULED`

The RPC may additionally accept only these allowlisted status filters:

- `NEEDS_CORRECTION`
- `APPROVED`
- `REJECTED`
- `ACTIVATED`

`APPROVED` is presented through a separate activation filter/view and is not
mixed into the default review queue. `REJECTED` and `ACTIVATED` are never in the
default queue. An unknown status fails with the typed invalid-data response.

An optional application-type filter is allowed only when implemented directly
from the canonical NEW/CLAIM type values. Search is outside V1-R07.

### Queue ordering and pagination

Ordering is frozen as:

1. `created_at ASC`
2. `id ASC`

This processes the oldest actionable applications first with a deterministic
tie-breaker.

Pagination is keyset-only with a `(created_at, id)` cursor. The default page
size is 25 and the maximum is 50. Invalid page sizes and malformed or
inconsistent cursors fail with the typed invalid-data response. No unbounded
staff read is permitted.

### Queue projection

The queue returns only bounded operational fields:

- application ID;
- application type;
- application status;
- `created_at` and `updated_at`;
- the canonical assigned/reviewer identifier when operationally useful;
- a minimal NEW-business summary for NEW applications;
- a minimal CLAIM-target summary for CLAIM applications;
- canonical `directory_entities.id` when a target exists.

The queue must not expose full applicant/profile rows or unrelated PII.
Required identity, enum, timestamp, cursor, and projection fields are parsed
strictly and fail closed when malformed.

## 8. Staff Detail RPC

PART 1 must add one bounded staff application detail RPC. It requires an
authenticated session and `business_applications.read` on every call.

The projection may include only data needed for the existing review workflow:

- application identity, type, status, and timestamps;
- NEW application business context;
- CLAIM target context and canonical Directory entity ID;
- applicant display name and phone;
- correction and rejection reasons;
- required contact and visit information;
- stored correction/contact/visit history where operationally necessary;
- action-relevant state.

No arbitrary profile data may be returned. Generic staff notes and a general
audit-log browser are outside V1-R07.

## 9. Existing Staff Mutations

V1-R07 reuses these existing server mutations without duplication:

- `staff_begin_application_review`
- `staff_return_application_for_correction`
- `staff_mark_application_contacted`
- `staff_schedule_application_visit`
- `staff_approve_business_application`
- `staff_reject_business_application`
- `staff_activate_business_application`

The server is the only lifecycle transition authority. Flutter must never
manufacture a status transition or assume success before receiving the
authoritative server result.

## 10. Activation

Approval and activation remain separate. `APPROVED → ACTIVATED` occurs only
through the existing activation RPC. V1-R07 must not create another activation
mutation or a new activation-only role.

Activation UX is available only when the granular capability projection
contains the existing activation permission and the canonical application
status is `APPROVED`. The server revalidates both authority and transition.
The existing V1 role/permission assignment may remain; broader RBAC refinement
is deferred.

## 11. Concurrency

Existing staff mutations retain `FOR UPDATE` plus transition validation while
the application row is locked. V1-R07 must not add a separate optimistic
version scheme solely for staff transitions or introduce client-side
concurrency authority. When actions race, only a transition that is valid when
the lock is held may commit.

## 12. Error Contract

Reuse existing typed SQLSTATE conventions where applicable:

- `P0AUT` — unauthenticated;
- `P0PER` — permission denied;
- `P0NOT` — application or required target not found;
- `P0TRA` — invalid lifecycle transition;
- `P0DAT` — invalid data, filter, page size, cursor, or projection;
- `P0COR` — correction reason required;
- `P0REJ` — rejection reason required;
- `P0CLM` — target is not claimable;
- `P0OWN` — ownership/provisioning conflict.

Do not add `P0CON` for staff transition races unless implementation evidence
proves the existing locked transition semantics insufficient. Unknown server
codes and malformed projections fail closed, and raw server messages must not
become user-facing behavior.

## 13. Audit Contract

Existing same-transaction audit writes remain authoritative for staff
mutations. They continue to record actor identity, action, target/application,
status-transition context, and required reason/context already captured by the
RPC. No audit schema redesign or audit-history UI is included.

## 14. Database Change Contract

Assessment: **OPTION B — SMALL ADDITIVE MIGRATION REQUIRED**

Planned migration:

`supabase/migrations/00021_staff_application_operations_foundation.sql`

It may add only:

1. `business_applications.read` permission;
2. its appropriate existing role-permission assignment;
3. current-session granular staff application capability RPC;
4. bounded staff queue RPC;
5. bounded staff application detail RPC;
6. a queue-supporting index justified by the frozen status/order/cursor contract;
7. explicit `PUBLIC` and `anon` EXECUTE revocation;
8. `authenticated` EXECUTE grants for client-facing RPCs.

Earlier migrations must not be altered. The migration must not redesign the
`business_applications` table, staff membership tables, roles/permissions
model, audit schema, or existing mutation functions.

All client-facing staff reads must require an authenticated session, validate
the canonical staff permission server-side, return bounded projections, fail
closed, use safe `SECURITY DEFINER` and fixed `search_path` conventions where
applicable, revoke `PUBLIC`/`anon` execution, and avoid client-side
`service_role` use.

## 15. Flutter Domain and Gateway Contract

Reuse and extend `BusinessApplicationStaffGateway` and
`SupabaseBusinessApplicationStaffGateway`. Do not create a parallel mutation
gateway.

The gateway adds:

- current-session capability read;
- bounded queue read;
- bounded detail read.

Add strict bounded projection models for staff capabilities, application
summary, application detail, and page/cursor results as needed. Reuse canonical
business application status/type models where structurally safe. Flutter must
not parse arbitrary raw table rows.

## 16. Flutter Provider Contract

Add only:

- `StaffAccessProvider` — current-session capability resolution;
- `StaffApplicationQueueProvider` — filters, keyset pagination, loading,
  loading-more, error, and retry;
- `StaffApplicationDetailProvider` — detail read, existing mutations, and
  authoritative reload after mutations where required.

Providers may derive presentation availability from granular capability plus
canonical status. They must not duplicate server transition logic or install a
locally manufactured status.

## 17. Route Access Contract

Access states are:

- **Logged out:** show or signpost authentication required; make no privileged
  read.
- **Authenticated, capabilities unresolved:** show only access-resolution
  loading; render no privileged data.
- **Authenticated, no read permission:** show access denied; render no queue or
  detail data.
- **Authorized:** allow the relevant staff read RPC to load.

Hiding the entry or route is not authorization. Every RPC remains authoritative.
Expired or revoked access fails closed on subsequent server calls and must not
leave stale privileged content visible.

## 18. Staff UI Contract

Required screens:

1. Staff Application Queue.
2. Staff Application Review / Detail.

Queue states must cover access resolving, access denied, loading, empty, error,
retry, loaded, and pagination/loading-more.

Detail states must cover loading, not found/unavailable, permission denied,
error, loaded, mutation pending, mutation failure, and successful authoritative
refresh.

Expose only these existing actions where granular permission and current
canonical status both allow them:

- Begin review;
- Return for correction;
- Mark contacted;
- Schedule visit;
- Approve;
- Reject;
- Activate.

Use confirmation or bounded input UX for required reasons, contact data, and
visit data. Generic staff notes and lifecycle redesign are forbidden.

## 19. Explicit Out of Scope

V1-R07 excludes:

- a separate admin application or web target;
- a super-admin dashboard;
- generalized RBAC or arbitrary staff/user role editing;
- staff self-enrollment;
- user banning, account destruction, or impersonation;
- bulk operations;
- analytics or advanced reporting;
- an audit-log browser;
- generic staff notes;
- application search;
- taxonomy editing;
- Directory profile editing on behalf of businesses;
- media or marketplace moderation;
- CRM or support tickets;
- subscriptions, payments, ads, or push campaigns;
- business lifecycle redesign.

## 20. Test Contract

Focused tests are required during implementation.

### Server and security

- guest and ordinary authenticated callers denied;
- inactive, future-effective, and expired memberships denied;
- permission-specific access and granular capability projection;
- bounded queue/detail projections and PII omission;
- allowed and invalid filters;
- page-size bounds, cursor correctness, and deterministic ordering;
- `PUBLIC`/`anon` EXECUTE revoked and authenticated grants explicit;
- existing mutation authority, locking, and audit behavior unchanged.

### Flutter and domain

- strict projection parsing;
- unknown status/type and malformed required fields fail closed;
- typed SQLSTATE mapping;
- granular capabilities;
- queue pagination, filtering, error, and retry;
- detail reads and mutation result handling;
- stale-result protection where relevant;
- action availability from permission plus canonical status.

### Widget and routing

- logged-out and unauthorized deep links;
- unresolved-capability state with no privileged-data flash;
- authorized queue and detail;
- empty, error, retry, and pagination states;
- confirmation/input paths for every existing staff action;
- activation only for `APPROVED` plus activation permission;
- denied or revoked access fails safely.

The full repository suite must not run repeatedly during implementation. The
existing 1909/1909 result remains reusable until shared changes invalidate it.
Run a new full suite once at the integrated V1-R07 phase gate if justified.

## 21. Scope Protection

Direct staff SELECT widening on raw application/profile/history tables is
forbidden. No earlier migration may be edited. No lifecycle, RBAC, audit,
Directory, media, marketplace, billing, advertising, or account-administration
scope may be added under V1-R07 without a new architect decision.
