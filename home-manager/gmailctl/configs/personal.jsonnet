// Gmail filters for josh@joshsymonds.com

local lib = import 'gmailctl.libsonnet';
local common = import 'lib/common-rules.libsonnet';

// Your actual high-volume retail senders (from analysis)
local retailSenders = [
  '*@email.bananarepublic.com',
  '*@email.lovesac.com', 
  '*@mail.crutchfield.com',
  '*@coyuchi.com',
  '*@em.calvinklein.com',
  '*@handupgloves.com',
  '*@paninos.ccsend.com',
  // Additional retail from analysis
  '*@mail.zillow.com',
  '*@joycoast.com',
];

// GitHub notification types (most proven gmailctl pattern)
local githubNotifications = [
  { type: 'assign', label: 'assigned' },
  { type: 'author', label: 'author' },
  { type: 'comment', label: 'commented' },
  { type: 'mention', label: 'mentioned', important: true },
  { type: 'push', label: 'pushed' },
  { type: 'review_requested', label: 'review-requested', important: true },
  { type: 'security_alert', label: 'security-alert', important: true },
  { type: 'state_change', label: 'state-changed' },
  { type: 'subscribed', label: 'watching' },
  { type: 'team_mention', label: 'team-mentioned', important: true },
];

// Generate GitHub rules (proven pattern from research)
local githubRules = std.flattenArrays([
  [
    {
      filter: {
        and: [
          { from: 'notifications@github.com' },
          { cc: notification.type + '@noreply.github.com' },
        ],
      },
      actions: {
        archive: if std.objectHas(notification, 'important') && notification.important then false else true,
        labels: ['github/' + notification.label],
        markImportant: if std.objectHas(notification, 'important') && notification.important then true else null,
      },
    }
  ]
  for notification in githubNotifications
]);

local rules = 
  // GitHub rules first (they're specific and your #1 sender at 10.8%)
  githubRules +
  [
    // PRIORITY 1: Aggressive unread cleanup (you have 435/500 unread!)
    {
      filter: {
        and: [
          { query: 'is:unread' },
          { query: 'older_than:1m' },  // Even more aggressive given your situation
          { not: { query: 'is:starred' } },
          { not: { query: 'is:important' } },
          // Never archive financial - removed label check due to gmailctl limitation
        ],
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ['auto-archived/old-unread'],
      },
    },

    // CRITICAL: Protect potentially important emails
    {
      filter: {
        or: [
          { from: 'josh@joshsymonds.com' },  // Emails to yourself
          { subject: 'urgent' },
          { subject: 'emergency' },
          { subject: 'asap' },
          { subject: 'important' },
        ],
      },
      actions: {
        star: true,
        markImportant: true,
        labels: ['⭐-priority'],
      },
    },

    // Financial - NEVER auto-archive (from your analysis + best practices)
    {
      filter: {
        or: [
          { from: '*@chase.com' },
          { from: '*@venmo.com' },
          { from: '*@email.venmo.com' },
          { from: '*@mint.com' },
          { from: '*@wellsfargo.com' },
          { from: '*@bankofamerica.com' },
          { from: '*@americanexpress.com' },
          { from: '*@capitalone.com' },
          { from: '*@schwab.com' },
          { from: '*@fidelity.com' },
          { from: '*@vanguard.com' },
          { from: '*bank*' },
          { subject: 'payment' },
          { subject: 'invoice' },
          { subject: 'statement' },
        ],
      },
      actions: {
        labels: ['💰-money'],
        markImportant: true,
        // NO archive - keep in inbox
      },
    },

    // Calendar events - keep visible (best practice)
    {
      filter: {
        or: [
          { from: 'calendar-notification@google.com' },
          { has: 'filename:invite.ics' },
        ],
      },
      actions: {
        labels: ['📅-calendar'],
        star: true,
      },
    },

    // Retail emails (30% of your inbox!)
    {
      filter: {
        or: [{ from: sender } for sender in retailSenders],
      },
      actions: {
        labels: ['🛍️-shopping'],
        archive: true,
      },
    },

    // Social/Events (from your analysis)
    {
      filter: {
        or: [
          { from: '*@mailva.evite.com' },  // 2.4% of your inbox
          { from: '*@linkedin.com' },       // 2.8% of your inbox
          { from: '*@todoist.com' },
          { from: '*@facebookmail.com' },
          { from: '*@twitter.com' },
        ],
      },
      actions: {
        labels: ['💬-social'],
        archive: true,
      },
    },

    // Amazon & orders - star for tracking
    {
      filter: {
        from: '*@amazon.com',
      },
      actions: {
        labels: ['📦-orders'],
        star: true,
      },
    },

    // Kickstarter/BackerKit (from your analysis)
    {
      filter: {
        or: [
          { from: '*@kickstarter.com' },
          { from: '*@backerkit.com' },
        ],
      },
      actions: {
        labels: ['crowdfunding'],
        archive: true,
      },
    },

    // Travel - star for easy access
    {
      filter: {
        or: [
          { from: '*@airbnb.com' },
          { from: '*@booking.com' },
          { from: '*@expedia.com' },
          { from: '*airline*' },
          { from: '*@lyft.com' },
          { from: '*@uber.com' },
          { subject: '*flight*' },
          { subject: '*boarding pass*' },
          { subject: '*itinerary*' },
          { subject: '*confirmation number*' },
        ],
      },
      actions: {
        labels: ['✈️-travel'],
        star: true,
        markImportant: true,
      },
    },

    // Health-related emails
    {
      filter: {
        or: [
          { from: '*@myhealth*' },
          { from: '*@healthcare*' },
          { from: '*clinic*' },
          { from: '*hospital*' },
          { from: '*doctor*' },
          { from: '*dental*' },
          { from: '*medical*' },
          { query: 'appointment' },
          { query: 'prescription' },
        ],
      },
      actions: {
        labels: ['🏥-health'],
        markImportant: true,
        star: true,
      },
    },

    // Auto-archive accepted calendar invites (clever pattern from research)
    {
      filter: {
        and: [
          { has: 'filename:invite.ics' },
          { query: 'accepted OR "Yes, I\'ll attend"' },
        ],
      },
      actions: {
        archive: true,
        labels: ['calendar/accepted'],
      },
    },

    // Newsletter management with plus addressing (best practice)
    {
      filter: { to: 'josh@joshsymonds.com+*' },
      actions: {
        labels: ['plus-addressed'],
        archive: true,
      },
    },

    // Bulk mail catch-all (68% of your emails have list headers!)
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

    // Automated senders
    {
      filter: {
        or: [
          { from: '*noreply*' },
          { from: '*no-reply*' },
          { from: '*donotreply*' },
          { from: '*notifications*' },
          { from: '*automated*' },
        ],
      },
      actions: {
        labels: ['automated'],
        archive: true,
      },
    },

    // Real humans filter (what's left after all other filters)
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
        labels: ['👤-humans'],
        markImportant: true,
      },
    },
  ];

{
  version: 'v1alpha3',
  author: {
    name: 'Josh Symonds',
    email: 'josh@joshsymonds.com',
  },
  rules: rules,
  labels: [
    // Hierarchical labels (best practice)
    { name: 'auto-archived' },
    { name: 'auto-archived/old-unread' },
    { name: 'automated' },
    { name: 'bulk' },
    { name: '📅-calendar' },
    { name: 'calendar/accepted' },
    { name: 'crowdfunding' },
    { name: 'github' },
  ] + [
    { name: 'github/' + n.label }
    for n in githubNotifications
  ] + [
    { name: '🏥-health' },
    { name: '👤-humans' },
    { name: '💰-money' },
    { name: '📦-orders' },
    { name: 'plus-addressed' },
    { name: '⭐-priority' },
    { name: '🛍️-shopping' },
    { name: '💬-social' },
    { name: '✈️-travel' },
  ],
}
