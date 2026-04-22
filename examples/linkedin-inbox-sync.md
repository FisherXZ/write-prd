# LinkedIn Message Inbox Sync — Feature Spec

**Branch:** `feat/linkedin-inbox-sync`  
**Status:** Draft — for review

---

## 1. TL;DR

Ingest a user's LinkedIn message history into The Hog so SDRs can read, search, and reply to LinkedIn DMs without leaving the app. Replies sent from The Hog are posted back to LinkedIn via OAuth + Messaging API and automatically logged as lead activity. V1 targets read + reply parity; sending net-new cold outreach from The Hog is V2.

---

## 2. User Narrative

Marcus is an SDR at a growth-stage B2B SaaS company. He runs outbound on LinkedIn every day — 20–30 new connection requests, follow-up messages to warm prospects, replies to inbound DMs from people who saw his content. Every afternoon he switches between The Hog (where his leads live) and LinkedIn (where the conversation history lives). He's constantly copy-pasting context.

Today Marcus opens The Hog. Under each lead in his pipeline he sees a new **Messages** tab. It shows the full LinkedIn DM thread with that person — every message, timestamped, in order. He doesn't have to go to LinkedIn to remember what was last said.

A lead named Sarah replied to his follow-up this morning: "Happy to chat, what are you solving for?" Marcus types his reply directly in The Hog message composer and hits Send. The message posts to LinkedIn. Sarah sees it in her LinkedIn inbox. Marcus sees a green "Sent" badge in The Hog thread.

The reply is automatically logged in Sarah's activity feed: *"LinkedIn message sent — Apr 21, 10:14am."* His manager opens Sarah's lead card later and sees the full conversation history without asking Marcus to forward anything.

Marcus's teammate Jordan, same org, opens her own LinkedIn inbox sync. She sees only her own DMs — Marcus's threads are scoped to his account. LinkedIn OAuth is per-user, not per-org.

---

## 3. Why This Feature

### 3.1 Competitive context
Every mature sales engagement platform ships native LinkedIn inbox integration: Salesloft and Outreach both surface LinkedIn DMs in the activity timeline. Apollo.io shows LinkedIn conversation history inline on contact records. The Hog's SDR users are context-switching to LinkedIn 5–10x per day — a workflow tax that makes the platform feel incomplete relative to alternatives.

### 3.2 Product thesis
The Hog's V2 thesis is company-centric data: all signals about a lead — posts, news, G2 reviews, email activity — unified in one place. LinkedIn DMs are the highest-signal 1:1 interaction an SDR has with a prospect. Not surfacing them in The Hog creates a gap in the "single source of truth" promise.

### 3.3 Leverage on existing investment
- `leads` table, lead activity log, and `people` tables already exist — we add a `linkedin_messages` table and link to existing FKs.
- LinkedIn OAuth (for profile scraping) is already partially implemented. The messaging API scope (`w_member_social`) is additive.
- The activity timeline UI already renders timestamped events. Rendering messages is a new event type, not a new UI component.

### 3.4 Observability / learning opportunity
We don't yet know how frequently SDRs message the same lead vs. spray-and-pray. Shipping inbox sync gives us exact message cadence data per lead, per user — which directly informs the headless agent executor's default credit cap and playbook recommendations.

---

## 4. Non-Goals

- **Not shipping V1:** Sending net-new cold outreach from The Hog. V1 is reply-only (existing thread required). Reason: cold outreach creates spam risk on LinkedIn's platform; reply-to-existing-thread is lower risk and lower review burden.
- **Not shipping V1:** Group message / InMail support. Standard DMs only.
- **Explicitly out of scope:** LinkedIn connection request automation. We do not touch connection workflows in this feature.
- **Future consideration only:** Org-wide inbox aggregation (manager sees all rep DMs). V1 is per-user OAuth only.
- **Future consideration only:** AI-suggested replies surfaced inline in the message composer.

---

## 5. Scope

### 5.1 Entry points
- **Lead card → Messages tab** (new tab, renders alongside Activity, Assets, Notes)
- **Notifications** — if a lead replies to a thread, fire an in-app notification linking to the lead card

### 5.2 Objects touched

**Existing objects, extended:**
- `linkedin_profiles` — no schema change; used as FK source for message threading
- `leads` — no schema change; `person_id` FK used to join to LinkedIn identity
- `notifications` — new notification type `linkedin_message_received`

**New objects introduced:**
- `linkedin_oauth_tokens` — per-user LinkedIn OAuth credentials (`user_id`, `access_token`, `refresh_token`, `expires_at`, `linkedin_member_id`, `scopes`)
- `linkedin_conversations` — one row per DM thread (`id`, `linkedin_conversation_id`, `participant_linkedin_ids` JSONB, `last_synced_at`, `lead_id` nullable FK)
- `linkedin_messages` — one row per message (`id`, `conversation_id` FK, `sender_linkedin_id`, `body_text`, `sent_at`, `direction` ENUM 'inbound'|'outbound', `linkedin_message_id`, `sync_status`)

### 5.3 Data flow map

```
User connects LinkedIn account
  → GET /api/integrations/linkedin/oauth/start
      → redirects to LinkedIn OAuth consent screen (scopes: r_messages, w_member_social)
  → LinkedIn redirects to /api/integrations/linkedin/oauth/callback
      → exchanges code for tokens
      → upserts linkedin_oauth_tokens for user
      → triggers BullMQ: sync-linkedin-inbox (initial full sync)

BullMQ sync-linkedin-inbox task runs
  → fetches /v2/conversations from LinkedIn API (paginated)
  → for each conversation:
      → upserts linkedin_conversations
      → fetches messages for conversation
      → upserts linkedin_messages
      → attempts to resolve lead_id via person identity matching
  → updates last_synced_at

Scheduled sync (every 15 min per connected user)
  → BullMQ sync-linkedin-inbox with since=last_synced_at (delta sync)
  → fires in-app notification if new inbound message found for known lead

User opens lead card → Messages tab
  → GET /api/leads/[leadId]/linkedin-messages
      → joins linkedin_conversations → linkedin_messages via lead_id FK
      → returns thread sorted by sent_at ASC

User sends reply
  → POST /api/leads/[leadId]/linkedin-messages
      → validates user has valid linkedin_oauth_token
      → POST to LinkedIn /v2/messages API
      → on success: inserts linkedin_messages (direction='outbound')
      → logs lead activity event: 'linkedin_message_sent'
      → returns { success: true, messageId }
```

---

## 6. Core Workflow

### Step 1. User connects LinkedIn account

- **User intent:** Grant The Hog access to their LinkedIn DMs.
- **Input:** User clicks "Connect LinkedIn" in Settings → Integrations.
- **System logic:** Initiates OAuth 2.0 PKCE flow. Requests scopes `r_messages` and `w_member_social`. Stores tokens in `linkedin_oauth_tokens` encrypted at rest.
- **Edge case:** LinkedIn denies the `r_messages` scope (user declines) → show clear error: "LinkedIn inbox sync requires message permission. Please reconnect and approve all permissions." Do not partially connect.

### Step 2. Initial inbox sync runs

- **User intent:** See their existing message history in The Hog.
- **Input:** Triggered automatically post-OAuth; also available via "Sync now" button.
- **System logic:** BullMQ task fetches all conversations paginated, up to 90 days. Stores messages. Runs identity resolution to link conversations to existing leads via `linkedin_member_id` → `linkedin_profiles` → `people` → `leads`.
- **Edge case:** A conversation participant has no matching lead → conversation stored but `lead_id` is NULL. Not shown in any lead card. Discoverable later if the lead is created.

### Step 3. User reads message thread on lead card

- **User intent:** See conversation history with a specific lead.
- **Input:** User clicks Messages tab on lead card.
- **System logic:** Fetches from `linkedin_messages` joined via `lead_id`. Renders messages with sender name, timestamp, direction indicator (sent vs. received).
- **Edge case:** No conversation linked to this lead → show empty state: "No LinkedIn messages yet. Messages will appear here once you've exchanged DMs with this person on LinkedIn."

### Step 4. User sends reply from The Hog

- **User intent:** Reply to a lead without switching to LinkedIn.
- **Input:** User types message in composer, clicks Send.
- **System logic:** POST to LinkedIn Messaging API using user's stored access token. On 200: insert outbound message row, log lead activity. On 4xx: surface error to user. On 401: mark token as expired, prompt reconnect.
- **Edge case:** LinkedIn API returns 429 (rate limit) → show "LinkedIn rate limit reached. Try again in 60 seconds." Do not queue silently — user expects immediate feedback.

### Step 5. Ongoing delta sync fires

- **User intent:** New inbound messages appear automatically.
- **Input:** BullMQ cron every 15 minutes per connected user.
- **System logic:** Fetches messages newer than `last_synced_at`. If new inbound message for a known lead → fire `linkedin_message_received` notification.
- **Edge case:** User's token has expired → log sync failure, send one in-app notification: "Your LinkedIn connection expired. Reconnect to resume inbox sync." Do not fire repeated notifications.

---

## 7. Technical Architecture

### 7.1 System components

| Component | Files (new / modified) | Responsibility |
|-----------|------------------------|----------------|
| Migration | `linkedin_inbox_sync.sql` | New tables, indexes, encrypted token column |
| OAuth routes | `app/api/integrations/linkedin/oauth/` | OAuth start, callback, disconnect |
| Messages API | `app/api/leads/[leadId]/linkedin-messages/route.ts` | Read thread, post reply |
| Sync task | `src/bullmq/tasks/sync-linkedin-inbox.ts` | Full + delta inbox sync |
| Scheduler | `src/bullmq/scheduler.ts` (modified) | Register 15-min sync cron per connected user |
| Data layer | `lib/data/linkedin-messages.ts` | CRUD for conversations + messages |
| Lead card UI | `components/leads/LeadCard.tsx` (modified) | Add Messages tab |
| Messages UI | `components/leads/LinkedInMessages.tsx` (new) | Thread view + composer |

### 7.2 Data model

- `linkedin_oauth_tokens` is 1:1 with `users` (one LinkedIn account per Hog user)
- `linkedin_conversations` is N:1 with `leads` (one lead can have at most one LinkedIn conversation per OAuth user)
- `linkedin_messages` is N:1 with `linkedin_conversations`
- Hot queries: messages by lead_id (indexed), messages by conversation ordered by sent_at (indexed)

### 7.3 Critical design decisions

**Per-user OAuth, not per-org**
- **Problem:** LinkedIn's API terms prohibit shared credentials. Org-level OAuth would require one LinkedIn account to read all reps' DMs — not technically possible and a ToS violation.
- **Decision:** Each user connects their own LinkedIn account. Conversations are scoped to the connecting user.
- **Why:** Only viable option under LinkedIn's API terms. Aligns with industry practice (Salesloft, Outreach both use per-rep OAuth).

**Delta sync via `last_synced_at`, not webhooks**
- **Problem:** LinkedIn's Messaging API does not offer webhooks for new messages. We must poll.
- **Decision:** 15-minute BullMQ cron per connected user, fetching messages since `last_synced_at`.
- **Why:** 15 minutes is acceptable latency for async DM context. Shorter intervals risk hitting LinkedIn's rate limits (which are undocumented and enforced aggressively). We can tighten this post-launch with data.

**Reply-only in V1, no cold outreach**
- **Problem:** Sending unsolicited LinkedIn messages from The Hog creates risk: LinkedIn's anti-spam systems flag bulk message patterns, which could get user accounts restricted.
- **Decision:** V1 only allows replying to existing threads (where the lead already messaged the user, or the user messaged the lead directly from LinkedIn).
- **Why:** Reply-to-existing-thread is indistinguishable from normal LinkedIn usage. New cold outreach from an API client is a known LinkedIn policy gray area.

**Encrypted token storage**
- **Problem:** LinkedIn access tokens grant access to a user's DMs — extremely sensitive.
- **Decision:** Encrypt `access_token` and `refresh_token` at rest using application-level encryption (AES-256) before storing in Postgres.
- **Why:** Supabase encrypts the DB at rest, but field-level encryption adds defense-in-depth against SQL injection or backup leaks.

---

## 8. Security & Permissions

- LinkedIn OAuth tokens are readable only by the owning user (RLS: `user_id = auth.uid()`)
- `linkedin_messages` are readable by org members who have the linked lead in their project (join-based RLS)
- Disconnect endpoint (`DELETE /api/integrations/linkedin/oauth`) hard-deletes the token row and stops the sync cron for that user

## 9. Observability & Auditability

**PostHog events:**
- `linkedin_oauth_connected` — user connects LinkedIn account
- `linkedin_oauth_disconnected`
- `linkedin_inbox_sync_completed` — `{ messages_synced, conversations_synced, leads_linked, duration_ms }`
- `linkedin_message_sent` — `{ lead_id, conversation_id }`
- `linkedin_sync_failed` — `{ error_type, user_id }`

**Logging:** Every sync task logs start, page count, and final counts. Every send attempt logs API status code.

---

## 10. Definition of Done

1. Migration lands clean + TypeScript type regeneration complete.
2. OAuth connect → callback → token stored → initial sync fires end-to-end.
3. Messages tab visible on lead card for leads with linked LinkedIn identity.
4. Reply sends to LinkedIn API and appears in LinkedIn inbox within 30 seconds.
5. Sent reply appears immediately in The Hog thread (optimistic insert).
6. Delta sync picks up new inbound messages within 15 minutes.
7. Token expiry handled: user sees reconnect prompt, sync pauses cleanly.
8. RLS: user cannot read another user's LinkedIn tokens or conversations.
9. PostHog events visible in dashboard for all 5 event types.
10. Manual E2E: connect → read thread → reply → verify in LinkedIn → disconnect.

---

## 11. Open Questions

1. **LinkedIn API access tier** — The Messaging API requires LinkedIn Marketing Developer Platform approval. Do we have this, or is this a blocker? Recommendation: confirm before committing to V1 timeline. If not approved, V1 must be de-scoped to display-only (scrape-based, no send).
2. **Rate limits** — LinkedIn's undocumented rate limits. Recommendation: start with 15-min cron, monitor for 429s in the first week, adjust interval based on observed errors.
3. **Identity resolution confidence** — If a LinkedIn member has no matching `linkedin_profiles` row in The Hog, the conversation won't link to a lead. Recommendation: add a manual "link to lead" UI on the Inbox view as a fallback for V1.
4. **Historical depth** — 90-day initial sync is an assumption. Recommendation: make this configurable per user (30 / 90 / 180 days) with a credit or storage consideration.
5. **Notification volume** — If a power user has 50 active threads, the 15-min sync could fire 50 notifications. Recommendation: batch notifications ("3 new LinkedIn messages from leads") rather than one per message.

---

## 12. Appendix

**LinkedIn API references:**
- Conversations API: `GET /v2/conversations`
- Messages API: `GET /v2/messages`, `POST /v2/messages`
- Required OAuth scopes: `r_messages`, `w_member_social`
- Developer program: LinkedIn Marketing Developer Platform (application required)

**Competitive references:**
- Salesloft: per-rep LinkedIn OAuth, reply-from-app, DMs surfaced in activity timeline
- Outreach: same pattern; also supports InMail (V2 consideration)
- Apollo.io: LinkedIn activity shown on contact record; send requires LinkedIn Sales Navigator

**Related tickets:** linkedIn OAuth foundation (existing), lead activity log (existing)
