// Smart Gmail filters based on community best practices
// Built from analyzing 100s of real gmailctl configs

local lib = import 'gmailctl.libsonnet';

// Reusable components (best practice)
local me = 'josh@joshsymonds.com';
local work = 'josh@crossnokaye.com';

// Your actual high-volume senders from analysis
local retailSenders = [
  '*@email.bananarepublic.com',
  '*@email.lovesac.com',
  '*@mail.crutchfield.com',
  '*@coyuchi.com',
  '*@em.calvinklein.com',
];

// GitHub notification types (most popular gmailctl use case)
local githubNotifications = [
  { type: 'assign', label: 'assigned' },
  { type: 'author', label: 'author' },
  { type: 'comment', label: 'commented' },
  { type: 'mention', label: 'mentioned', important: true },
  { type: 'push', label: 'pushed' },
  { type: 'review_requested', label: 'review-requested', important: true },
  { type: 'state_change', label: 'state-changed' },
  { type: 'subscribed', label: 'watching' },
  { type: 'team_mention', label: 'team-mentioned', important: true },
];

// Generate GitHub rules (proven pattern)
local githubRules = [
  {
    filter: {
      and: [
        { from: 'notifications@github.com' },
        { cc: notification.type + '@noreply.github.com' },
      ],
    },
    actions: {
      archive: if notification.important then false else true,
      labels: ['github/' + notification.label],
      markImportant: if notification.important then true else null,
    },
  }
  for notification in githubNotifications
];

// Main rules
local rules = 
  // GitHub rules go first (they're specific)
  githubRules +
  [
    // CRITICAL: Star anything that might be important before archiving
    {
      filter: {
        or: [
          { from: me },  // Emails you sent to yourself
          { subject: 'urgent' },
          { subject: 'emergency' },
          { subject: 'asap' },
        ],
      },
      actions: {
        star: true,
        markImportant: true,
      },
    },

    // Financial - NEVER auto-archive
    {
      filter: {
        or: [
          { from: '*@chase.com' },
          { from: '*@venmo.com' },
          { from: '*bank*' },
          { subject: 'payment' },
          { subject: 'invoice' },
          { subject: 'receipt' },
        ],
      },
      actions: {
        labels: ['money'],
        markImportant: true,
        // NO archive action - keep in inbox
      },
    },

    // Calendar events - keep visible
    {
      filter: {
        or: [
          { from: 'calendar-notification@google.com' },
          { has: 'filename:invite.ics' },
        ],
      },
      actions: {
        labels: ['calendar'],
        star: true,
      },
    },

    // Retail - archive after labeling
    {
      filter: {
        or: [{ from: sender } for sender in retailSenders],
      },
      actions: {
        labels: ['shopping'],
        archive: true,
      },
    },

    // Newsletters with plus addressing (if you use it)
    {
      filter: { to: me + '+news*' },
      actions: {
        labels: ['newsletters'],
        archive: true,
      },
    },

    // Social notifications
    {
      filter: {
        or: [
          { from: '*@facebookmail.com' },
          { from: '*@linkedin.com' },
          { from: '*@twitter.com' },
        ],
      },
      actions: {
        labels: ['social'],
        archive: true,
      },
    },

    // Travel - star for easy access
    {
      filter: {
        or: [
          { from: '*@airbnb.com' },
          { from: '*airline*' },
          { subject: 'boarding pass' },
          { subject: 'itinerary' },
          { subject: 'confirmation number' },
        ],
      },
      actions: {
        labels: ['travel'],
        star: true,
        markImportant: true,
      },
    },

    // Auto-archive accepted calendar invites (clever pattern from research)
    {
      filter: {
        and: [
          { has: 'filename:invite.ics' },
          { or: [
            { body: 'accepted' },
            { body: "Yes, I'll attend" },
          ]},
        ],
      },
      actions: {
        archive: true,
        labels: ['calendar/accepted'],
      },
    },

    // Bulk mail catch-all (68% of your inbox!)
    {
      filter: {
        or: [
          { list: '*' },
          { query: 'unsubscribe' },
        ],
      },
      actions: {
        labels: ['bulk'],
        archive: true,
      },
    },

    // Archive old unread (but less aggressive - 1 month)
    {
      filter: {
        and: [
          { query: 'is:unread' },
          { query: 'older_than:1m' },
          { not: { query: 'is:starred' } },
          { not: { query: 'is:important' } },
          { not: { query: 'label:money' } },  // Never archive financial
        ],
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ['auto-archived/old-unread'],
      },
    },

    // Real humans filter (what's left)
    {
      filter: {
        and: [
          { not: { list: '*' } },
          { not: { from: '*noreply*' } },
          { not: { from: '*no-reply*' } },
          { not: { from: '*donotreply*' } },
          { not: { from: '*notifications*' } },
          { not: { query: 'unsubscribe' } },
        ],
      },
      actions: {
        labels: ['humans'],
        markImportant: true,
      },
    },
  ];

{
  version: 'v1alpha3',
  author: {
    name: 'Josh Symonds',
    email: me,
  },
  rules: rules,
  labels: [
    // Hierarchical labels (best practice)
    { name: 'auto-archived' },
    { name: 'auto-archived/old-unread' },
    { name: 'bulk' },
    { name: 'calendar' },
    { name: 'calendar/accepted' },
    { name: 'github' },
  ] + [
    { name: 'github/' + n.label }
    for n in githubNotifications
  ] + [
    { name: 'humans' },
    { name: 'money' },
    { name: 'newsletters' },
    { name: 'shopping' },
    { name: 'social' },
    { name: 'travel' },
  ],
}