// Gmail filters for josh@crossnokaye.com (work account)
// Enhanced with all best practices from research + personal config

local lib = import 'gmailctl.libsonnet';
local common = import 'lib/common-rules.libsonnet';

// Internal team members who send real emails
local teamMembers = [
  'kathryn@crossnokaye.com',
  'raphael@crossnokaye.com',
  'dmag@crossnokaye.com',
  'neenu@crossnokaye.com',
  'perry@crossnokaye.com',
  'frank@crossnokaye.com',
  'annie@crossnokaye.com',
  'katie@crossnokaye.com',
  'merc@crossnokaye.com',
  'mitch@crossnokaye.com',
  'taryn@crossnokaye.com',
  'jborneman@crossnokaye.com',
];

// Monitoring/DevOps services
local monitoringServices = [
  '*@honeycomb.io',
  '*@intruder.io',
  '*@pagerduty.com',
  '*@account.pagerduty.com',
  '*@md.getsentry.com',
  '*@alerts.mongodb.com',
  '*@grafana.com',
  '*@cypress.io',
  '*@rapid7.com',
];

// GitHub notifications (less common but using proven pattern)
local githubNotifications = [
  { type: 'assign', label: 'assigned' },
  { type: 'mention', label: 'mentioned', important: true },
  { type: 'review_requested', label: 'review-requested', important: true },
  { type: 'security_alert', label: 'security-alert', important: true },
  { type: 'comment', label: 'commented' },
  { type: 'push', label: 'pushed' },
  { type: 'state_change', label: 'state-changed' },
];

// Generate GitHub rules
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
  // GitHub rules first (proven pattern)
  githubRules +
  [
    // NUCLEAR: Archive ALL automated devops emails immediately
    // This is 17.4% of your inbox!
    {
      filter: {
        from: 'devops@crossnokaye.com',
      },
      actions: {
        labels: ['devops/robot'],
        archive: true,
        markRead: true,  // Mark as read too
        markImportant: false,
      },
    },

    // AGGRESSIVE: Archive old unread (91.4% unread!)
    {
      filter: {
        and: [
          { query: 'is:unread' },
          { query: 'older_than:1w' },  // Even more aggressive - 1 week
          { not: { query: 'is:starred' } },
          { not: { query: 'is:important' } },
        ],
      },
      actions: {
        archive: true,
        markRead: true,
        labels: ['auto-archived/old-unread'],
      },
    },

    // CRITICAL: Outages and incidents (BEFORE other filters)
    {
      filter: {
        or: [
          { subject: '*URGENT*' },
          { subject: '*EMERGENCY*' },
          { subject: '*CRITICAL*' },
          { subject: '*OUTAGE*' },
          { subject: '*DOWN*' },
          { subject: '*INCIDENT*' },
          { subject: '*urgent*' },
          { subject: '*emergency*' },
          { subject: '*critical*' },
          { subject: '*outage*' },
          { subject: '*down*' },
          { subject: '*incident*' },
          { subject: '*pager*' },
        ],
      },
      actions: {
        star: true,
        markImportant: true,
        labels: ['🚨-critical'],  // Emoji makes it stand out
        // NO archive - must stay visible
      },
    },

    // Real team members - ALWAYS visible
    {
      filter: {
        or: [{ from: member } for member in teamMembers],
      },
      actions: {
        labels: ['👥-team'],
        markImportant: true,
        // NO archive
      },
    },

    // Your direct boss/reports (add as needed)
    {
      filter: {
        or: [
          { from: 'dmag@crossnokaye.com' },  // Example - adjust to your manager
          { to: 'josh@crossnokaye.com' },   // Directly to you
        ],
      },
      actions: {
        labels: ['📨-direct'],
        star: true,
        markImportant: true,
      },
    },

    // Monitoring - Split critical vs noise
    {
      filter: {
        and: [
          { or: [{ from: service } for service in monitoringServices] },
          { or: [
            { subject: '*alert*' },
            { subject: '*ALERT*' },
            { subject: '*fail*' },
            { subject: '*FAIL*' },
            { subject: '*error*' },
            { subject: '*ERROR*' },
            { subject: '*critical*' },
            { subject: '*CRITICAL*' },
          ]},
        ],
      },
      actions: {
        labels: ['monitoring/alerts'],
        star: true,
        markImportant: true,
      },
    },

    // Non-critical monitoring → ARCHIVE
    {
      filter: {
        or: [{ from: service } for service in monitoringServices],
      },
      actions: {
        labels: ['monitoring/noise'],
        archive: true,
        markRead: true,
      },
    },

    // Honeycomb support (8.8% of inbox!) - Special handling
    {
      filter: {
        and: [
          { from: 'support@honeycomb.io' },
          { subject: '*ticket*' },
        ],
      },
      actions: {
        labels: ['support/honeycomb'],
        star: true,  // Active tickets need attention
      },
    },

    // Other Honeycomb → archive
    {
      filter: {
        from: '*@honeycomb.io',
      },
      actions: {
        labels: ['tools/honeycomb'],
        archive: true,
      },
    },

    // Cleary (7.4%) → ARCHIVE
    {
      filter: {
        from: '*@gocleary.com',
      },
      actions: {
        labels: ['tools/cleary'],
        archive: true,
        markRead: true,
      },
    },

    // Intruder security (4.8%) - could be important
    {
      filter: {
        and: [
          { from: '*@intruder.io' },
          { or: [
            { subject: '*vulnerability*' },
            { subject: '*security*' },
            { subject: '*critical*' },
          ]},
        ],
      },
      actions: {
        labels: ['security/critical'],
        star: true,
        markImportant: true,
      },
    },

    // Other Intruder → archive
    {
      filter: {
        from: '*@intruder.io',
      },
      actions: {
        labels: ['security/scans'],
        archive: true,
      },
    },

    // Drata compliance - keep visible but organized
    {
      filter: {
        or: [
          { from: '*@drata.com' },
          { from: '*@drata.intercom-mail.com' },
        ],
      },
      actions: {
        labels: ['compliance/drata'],
        // NO archive - compliance is important
      },
    },

    // Jira/Atlassian → mostly noise
    {
      filter: {
        or: [
          { from: '*@crossnokaye.atlassian.net' },
          { from: '*@e.atlassian.com' },
        ],
      },
      actions: {
        labels: ['tools/jira'],
        archive: true,
        markRead: true,
      },
    },

    // Google Docs comments - someone needs your input
    {
      filter: {
        from: 'comments-noreply@docs.google.com',
      },
      actions: {
        labels: ['docs/comments'],
        star: true,
        markImportant: true,
      },
    },

    // Calendar events (from personal best practices)
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

    // Auto-archive accepted calendar invites
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

    // Contracts and legal
    {
      filter: {
        or: [
          { from: '*@docusign.net' },
          { subject: '*contract*' },
          { subject: '*agreement*' },
          { subject: '*nda*' },
          { subject: '*signature*' },
        ],
      },
      actions: {
        labels: ['⚖️-legal'],
        star: true,
        markImportant: true,
      },
    },

    // Financial/expenses
    {
      filter: {
        or: [
          { from: '*@expensify.com' },
          { subject: '*expense*' },
          { subject: '*reimbursement*' },
          { subject: '*invoice*' },
          { subject: '*payment*' },
        ],
      },
      actions: {
        labels: ['💰-finance'],
        markImportant: true,
      },
    },

    // AWS via email (not devops@)
    {
      filter: {
        or: [
          { from: 'aws-root@crossnokaye.com' },
          { from: '*@amazon.com' },
          { from: '*@aws.amazon.com' },
        ],
      },
      actions: {
        labels: ['aws'],
        archive: true,
      },
    },

    // All remaining SaaS tools → ARCHIVE
    {
      filter: {
        or: [
          { from: '*@slack.com' },
          { from: '*@email.slackhq.com' },
          { from: '*@datawire.io' },
          { from: '*@tailscale.com' },
          { from: '*@okta.com' },
          { from: '*@1password.com' },
          { from: '*@greenhouse.io' },
          { from: '*@cypress.io' },
        ],
      },
      actions: {
        labels: ['tools/misc'],
        archive: true,
        markRead: true,
      },
    },

    // Recruiting spam
    {
      filter: {
        or: [
          { from: '*@powertofly.com' },
          { from: '*recruiter*' },
          { from: '*recruiting*' },
          { subject: '*opportunity*' },
          { subject: '*position*' },
        ],
      },
      actions: {
        labels: ['recruiting'],
        archive: true,
        markRead: true,
      },
    },

    // Marketing/Events/Newsletters (51.2% have list headers!)
    {
      filter: {
        or: [
          { list: '*' },
          { query: 'unsubscribe' },
          { from: '*@campaigns.*' },
          { from: '*@mail.*' },
          { from: '*@email.*' },
          { from: '*@engage.*' },
          { from: '*@reply.*' },
          { from: '*newsletter*' },
        ],
      },
      actions: {
        labels: ['bulk'],
        archive: true,
        markRead: true,
      },
    },

    // Auto-archive all remaining noreply
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
        markRead: true,
      },
    },

    // External humans (what's left)
    {
      filter: {
        and: [
          { not: { from: '*@crossnokaye.com' } },
          { not: { list: '*' } },
          { not: { from: '*noreply*' } },
          { not: { from: '*no-reply*' } },
          { not: { from: '*notifications*' } },
          { not: { query: 'unsubscribe' } },
        ],
      },
      actions: {
        labels: ['👤-external-human'],
        markImportant: true,
      },
    },
  ];

{
  version: 'v1alpha3',
  author: {
    name: 'Josh Symonds',
    email: 'josh@crossnokaye.com',
  },
  rules: rules,
  labels: [
    // Critical stuff first - emoji for primary action labels
    { name: '🚨-critical' },
    { name: '📨-direct' },
    { name: '👥-team' },
    { name: '👤-external-human' },
    
    // Hierarchical labels - no emoji on sub-labels or categories
    { name: 'auto-archived' },
    { name: 'auto-archived/old-unread' },
    { name: 'automated' },
    { name: 'aws' },
    { name: 'bulk' },
    { name: '📅-calendar' },  // Primary visual category
    { name: 'calendar/accepted' },
    { name: 'compliance' },
    { name: 'compliance/drata' },
    { name: 'devops' },
    { name: 'devops/robot' },
    { name: 'docs' },
    { name: 'docs/comments' },
    { name: '💰-finance' },  // Primary visual category
    { name: 'github' },
  ] + [
    { name: 'github/' + n.label }
    for n in githubNotifications
  ] + [
    { name: '⚖️-legal' },  // Primary visual category
    { name: 'monitoring' },
    { name: 'monitoring/alerts' },
    { name: 'monitoring/noise' },
    { name: 'recruiting' },
    { name: 'security' },
    { name: 'security/critical' },
    { name: 'security/scans' },
    { name: 'support' },
    { name: 'support/honeycomb' },
    { name: 'tools' },
    { name: 'tools/cleary' },
    { name: 'tools/honeycomb' },
    { name: 'tools/jira' },
    { name: 'tools/misc' },
  ],
}