# Claude Notify - Go Implementation Design Document

## Overview

Claude Notify is a cross-platform wrapper for Claude Code that monitors output and sends notifications based on user activity and output patterns. This document outlines the requirements, architecture, and development plan for rewriting the current bash implementation in Go.

## Requirements

### Functional Requirements

1. **Transparent Wrapping**
   - Must wrap the Claude binary without affecting its functionality
   - Preserve all terminal capabilities (colors, cursor movement, resize events)
   - Pass through all stdin/stdout/stderr without modification
   - Forward all signals (SIGINT, SIGTERM, etc.) to the child process
   - Exit with the same code as the wrapped process

2. **Notification Triggers**
   - Bell character detection (ASCII 0x07)
   - Question patterns (lines ending with "?")
   - Completion patterns ("done", "finished", "completed")
   - Error patterns ("error", "failed", "exception")
   - Idle timeout (no output for N seconds)
   - Claude process exit (normal or crash)

3. **Activity Detection**
   - **Linux**: Use tmux client activity when in tmux session
   - **macOS**: Use system-wide idle time via ioreg
   - **Fallback**: Output-based idle detection
   - User configurable timeout (default 2 minutes)

4. **Notification Delivery**
   - Send to ntfy.sh with configurable topic
   - Include contextual information (devspace, hostname, etc.)
   - Respect user preferences (force notify, quiet mode)
   - Log all notifications and suppressions

5. **Configuration**
   - Environment variables for runtime config
   - Config file support for persistent settings
   - Sensible defaults that work out of the box

### Non-Functional Requirements

1. **Performance**
   - Near-zero latency on I/O operations
   - Minimal CPU/memory overhead
   - No buffering that affects interactivity

2. **Reliability**
   - Graceful handling of notification failures
   - Proper cleanup on exit
   - No zombie processes

3. **Maintainability**
   - Clean, testable architecture
   - Platform-specific code isolated
   - Comprehensive logging for debugging

4. **Usability**
   - Drop-in replacement for claude command
   - Clear error messages
   - Optional verbose/debug mode

## Architecture

### High-Level Design

```
┌─────────────────┐
│   User Input    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│  claude-notify  │────▶│  IdleDetector    │
│     (main)      │     │  (interface)     │
└────────┬────────┘     └──────────────────┘
         │                        │
         │              ┌─────────┴─────────┐
         │              │                   │
         ▼              ▼                   ▼
┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
│  ProcessManager │  │ TmuxDetector │  │DarwinDetector│
│                 │  └──────────────┘  └──────────────┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│ OutputMonitor   │────▶│    Notifier      │
│                 │     │  (interface)     │
└────────┬────────┘     └──────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐     ┌──────────────────┐
│  Claude Binary  │     │  NtfyNotifier    │
└─────────────────┘     └──────────────────┘
```

### Component Breakdown

#### 1. Main Entry Point (`cmd/claude-notify/main.go`)
```go
type Config struct {
    IdleTimeout   time.Duration
    NtfyTopic     string
    NtfyServer    string
    ForceNotify   bool
    Devspace      string
    LogFile       string
    Verbose       bool
}

func main() {
    config := loadConfig()
    
    detector := createIdleDetector()
    notifier := createNotifier(config)
    
    manager := &ProcessManager{
        Config:   config,
        Detector: detector,
        Notifier: notifier,
    }
    
    os.Exit(manager.Run(os.Args[1:]))
}
```

#### 2. Process Manager (`pkg/process/manager.go`)
```go
type ProcessManager struct {
    Config   Config
    Detector IdleDetector
    Notifier Notifier
    
    cmd      *exec.Cmd
    pty      *os.File
    monitor  *OutputMonitor
}

func (pm *ProcessManager) Run(args []string) int {
    // 1. Start Claude with PTY
    // 2. Set up signal forwarding
    // 3. Start output monitoring
    // 4. Start idle checking
    // 5. Wait for completion
    // 6. Return exit code
}
```

#### 3. Idle Detection (`pkg/idle/detector.go`)
```go
type IdleDetector interface {
    IsUserIdle(timeout time.Duration) (bool, error)
    LastActivity() time.Time
}

// Platform-specific implementations
type TmuxIdleDetector struct {
    sessionName string
}

type DarwinIdleDetector struct{}

type OutputIdleDetector struct {
    lastActivity time.Time
    mu           sync.RWMutex
}
```

#### 4. Output Monitoring (`pkg/monitor/output.go`)
```go
type OutputMonitor struct {
    config   Config
    notifier Notifier
    detector IdleDetector
    
    patterns []Pattern
    buffer   *RingBuffer
}

type Pattern struct {
    Name     string
    Regex    *regexp.Regexp
    Priority string
    Tags     []string
    Handler  PatternHandler
}

type PatternHandler func(match string, context *Context) *Notification
```

#### 5. Notification System (`pkg/notify/notifier.go`)
```go
type Notification struct {
    Title    string
    Message  string
    Priority string
    Tags     []string
}

type Notifier interface {
    Send(notification *Notification) error
    ShouldNotify() bool
}

type NtfyNotifier struct {
    config   Config
    detector IdleDetector
    client   *http.Client
}
```

### Key Design Decisions

1. **PTY vs Pipes**: Use PTY for full terminal emulation support
2. **Interfaces**: Heavy use of interfaces for testability and platform flexibility
3. **Goroutines**: Separate goroutines for I/O copying, monitoring, and idle detection
4. **Ring Buffer**: Keep last N lines for context in notifications
5. **Plugin Pattern**: Extensible pattern matching system

## Testability Strategy

### Unit Tests

1. **Mock Interfaces**
```go
type MockIdleDetector struct {
    idle bool
}

func (m *MockIdleDetector) IsUserIdle(timeout time.Duration) (bool, error) {
    return m.idle, nil
}
```

2. **Pattern Matching Tests**
```go
func TestBellDetection(t *testing.T) {
    monitor := NewOutputMonitor(config, mockNotifier)
    line := "Test message\x07"
    
    notification := monitor.ProcessLine(line)
    
    assert.NotNil(t, notification)
    assert.Equal(t, "🔔 Claude needs attention", notification.Title)
}
```

3. **Integration Tests**
```go
func TestProcessManager(t *testing.T) {
    // Use echo command as mock claude
    manager := &ProcessManager{
        Config: testConfig,
        // ... mocks
    }
    
    exitCode := manager.Run([]string{"echo", "test"})
    assert.Equal(t, 0, exitCode)
}
```

### Testing Utilities

1. **Test Helpers**
```go
func NewTestConfig() Config
func NewMockNotifier() *MockNotifier
func CaptureOutput(f func()) string
```

2. **Fixture Data**
- Sample Claude output sessions
- Various terminal escape sequences
- Edge cases (binary output, large lines)

## Development Plan

### Phase 1: Core Infrastructure (Week 1)
- [ ] Project setup and structure
- [ ] Basic ProcessManager with PTY support
- [ ] Signal forwarding
- [ ] Simple I/O copying
- [ ] Exit code preservation

### Phase 2: Output Monitoring (Week 1-2)
- [ ] OutputMonitor implementation
- [ ] Pattern matching system
- [ ] Ring buffer for context
- [ ] Basic patterns (bell, questions)
- [ ] Unit tests for patterns

### Phase 3: Platform Detection (Week 2)
- [ ] IdleDetector interface
- [ ] Linux/tmux implementation
- [ ] macOS/ioreg implementation
- [ ] Fallback output-based detection
- [ ] Platform detection logic

### Phase 4: Notification System (Week 2-3)
- [ ] Notifier interface
- [ ] Ntfy.sh implementation
- [ ] Notification suppression logic
- [ ] Logging system
- [ ] Error handling

### Phase 5: Configuration & Polish (Week 3)
- [ ] Environment variable parsing
- [ ] Config file support (optional)
- [ ] Verbose/debug modes
- [ ] Comprehensive error messages
- [ ] Performance optimization

### Phase 6: Testing & Documentation (Week 3-4)
- [ ] Integration test suite
- [ ] Platform-specific testing
- [ ] Performance benchmarks
- [ ] User documentation
- [ ] Nix packaging updates

## Migration Strategy

1. **Parallel Installation**
   - Keep bash version as `claude-notify-legacy`
   - Install Go version as `claude-notify`
   - Update wrapper to choose based on flag

2. **Testing Period**
   - Run both versions in parallel
   - Compare notification behavior
   - Gather performance metrics

3. **Gradual Rollout**
   - Default to Go version with fallback
   - Remove bash version after stability confirmed

## Open Questions

1. **Configuration Format**: Should we support a config file, or stick to environment variables?
2. **Notification Batching**: Should rapid notifications be batched/rate-limited?
3. **Plugin System**: Should pattern matching be extensible via plugins?
4. **Multiple Notifiers**: Support for multiple notification backends?
5. **Metrics/Telemetry**: Should we collect usage statistics?

## Success Criteria

1. **Performance**: < 1ms added latency on I/O operations
2. **Reliability**: 0 crashes in 1000 hours of usage
3. **Compatibility**: Works with all Claude features
4. **User Experience**: Notifications delivered within 2s of trigger
5. **Code Quality**: 80%+ test coverage, all critical paths tested

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| PTY compatibility issues | High | Extensive testing on both platforms |
| Performance regression | Medium | Benchmark against bash implementation |
| Notification delivery failures | Low | Graceful degradation, local logging |
| Complex terminal sequences | Medium | Use proven PTY library |

## Next Steps

1. Review and refine requirements
2. Prototype PTY handling code
3. Set up project structure
4. Begin Phase 1 implementation

## References

- [creack/pty](https://github.com/creack/pty) - Go PTY utilities
- [ntfy.sh API](https://docs.ntfy.sh/) - Notification service
- [Claude Code](https://github.com/anthropics/claude-code) - Target application