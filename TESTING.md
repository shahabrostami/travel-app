# Testing Guide

## 🧪 Testing Philosophy

This project follows **Test-Driven Development (TDD)** principles:
- Write tests before or alongside implementation
- Every feature must have tests before merge
- Minimum 80% code coverage (95% for critical paths)
- All tests must pass before merging to main

---

## 📦 Testing Stack

- **Unit/Component Tests**: Jest + React Native Testing Library
- **State Management**: Zustand with renderHook
- **Coverage**: Jest built-in coverage
- **CI**: GitHub Actions

---

## 🚀 Running Tests

```bash
# Run all tests
npm test

# Run in watch mode (during development)
npm run test:watch

# Run with coverage
npm run test:coverage

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Run tests for CI (no watch, with coverage)
npm run test:ci
```

---

## 📁 Test Structure

```
__tests__/
├── unit/
│   ├── lib/           # Pure functions, utilities
│   ├── hooks/         # Custom React hooks
│   ├── store/         # Zustand stores
│   └── components/    # React components
├── integration/       # Multi-component workflows
└── e2e/              # End-to-end tests (future)
```

---

## ✍️ Writing Tests

### 1. Unit Test (Pure Function)

```typescript
// lib/distance.ts
export function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  // Haversine formula implementation
  return distance;
}

// __tests__/unit/lib/distance.test.ts
import { calculateDistance } from '@/lib/distance';

describe('calculateDistance', () => {
  it('calculates distance between two points', () => {
    const lisbon = { lat: 38.7223, lon: -9.1393 };
    const porto = { lat: 41.1579, lon: -8.6291 };

    const distance = calculateDistance(lisbon.lat, lisbon.lon, porto.lat, porto.lon);

    expect(distance).toBeCloseTo(274, 0); // ~274km
  });

  it('returns 0 for same location', () => {
    const distance = calculateDistance(0, 0, 0, 0);
    expect(distance).toBe(0);
  });
});
```

### 2. Component Test

```typescript
// components/meetup/MeetupCard.tsx
export function MeetupCard({ meetup, onPress }: Props) {
  return (
    <Pressable onPress={() => onPress(meetup.id)}>
      <Text>{meetup.title}</Text>
      <Text>{meetup.city}</Text>
      <Text>{meetup.current_attendees} attending</Text>
    </Pressable>
  );
}

// __tests__/unit/components/MeetupCard.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { MeetupCard } from '@/components/meetup/MeetupCard';

describe('MeetupCard', () => {
  const mockMeetup = {
    id: '123',
    title: 'Coffee & Coworking',
    city: 'Lisbon',
    current_attendees: 5,
  };

  it('renders meetup information', () => {
    const { getByText } = render(<MeetupCard meetup={mockMeetup} onPress={() => {}} />);

    expect(getByText('Coffee & Coworking')).toBeTruthy();
    expect(getByText('Lisbon')).toBeTruthy();
    expect(getByText('5 attending')).toBeTruthy();
  });

  it('calls onPress with meetup id when tapped', () => {
    const onPress = jest.fn();
    const { getByText } = render(<MeetupCard meetup={mockMeetup} onPress={onPress} />);

    fireEvent.press(getByText('Coffee & Coworking'));

    expect(onPress).toHaveBeenCalledWith('123');
  });
});
```

### 3. Hook Test (React Query)

```typescript
// hooks/useItineraries.ts
export function useItineraries(userId: string) {
  return useQuery({
    queryKey: ['itineraries', userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('itineraries')
        .select('*')
        .eq('user_id', userId);

      if (error) throw error;
      return data;
    },
  });
}

// __tests__/unit/hooks/useItineraries.test.ts
import { renderHook, waitFor } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useItineraries } from '@/hooks/useItineraries';

// Create a wrapper with QueryClient
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false }, // Disable retry for tests
    },
  });

  return ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('useItineraries', () => {
  it('fetches itineraries for user', async () => {
    const { result } = renderHook(
      () => useItineraries('user-123'),
      { wrapper: createWrapper() }
    );

    // Initially loading
    expect(result.current.isLoading).toBe(true);

    // Wait for data to load
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(result.current.data).toHaveLength(2);
  });
});
```

### 4. Store Test (Zustand)

```typescript
// store/authStore.ts
export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
}));

// __tests__/unit/store/authStore.test.ts
import { renderHook, act } from '@testing-library/react-native';
import { useAuthStore } from '@/store/authStore';

describe('authStore', () => {
  beforeEach(() => {
    useAuthStore.getState().logout(); // Reset store
  });

  it('initializes with no user', () => {
    const { result } = renderHook(() => useAuthStore());
    expect(result.current.user).toBeNull();
  });

  it('sets user on login', () => {
    const { result } = renderHook(() => useAuthStore());
    const mockUser = { id: '123', email: 'test@example.com' };

    act(() => {
      result.current.setUser(mockUser);
    });

    expect(result.current.user).toEqual(mockUser);
  });
});
```

---

## 🎯 Best Practices

### DO:
✅ Write descriptive test names (`it('should...')`)
✅ Test one thing per test
✅ Use `describe` blocks to group related tests
✅ Mock external dependencies (Supabase, APIs)
✅ Clean up after tests (reset stores, clear mocks)
✅ Test edge cases and error states
✅ Use `waitFor` for async operations

### DON'T:
❌ Test implementation details
❌ Write tests that depend on other tests
❌ Leave commented-out tests
❌ Skip tests without good reason
❌ Test third-party library code
❌ Hardcode dates (use relative dates)

---

## 🔄 TDD Workflow

1. **Write failing test first**
```bash
npm run test:watch  # Start watch mode
```

2. **Write minimal code to make it pass**

3. **Refactor**

4. **Repeat**

---

## 📊 Coverage Requirements

| Path | Min Coverage |
|------|--------------|
| Global | 80% |
| `lib/matching.ts` | 95% |
| `lib/supabase.ts` | 90% |
| Critical security/payment logic | 100% |

View coverage report:
```bash
npm run test:coverage
open coverage/lcov-report/index.html
```

---

## 🚨 Common Issues & Solutions

### Issue: "Cannot find module"
**Solution**: Check `moduleNameMapper` in `jest.config.js`

### Issue: "Timeout exceeded"
**Solution**: Increase timeout for async tests:
```typescript
it('does something async', async () => {
  // ...
}, 10000); // 10 second timeout
```

### Issue: "act() warning"
**Solution**: Wrap state updates in `act()`:
```typescript
await act(async () => {
  await result.current.fetchData();
});
```

---

## 🎓 Learning Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [React Native Testing Library](https://callstack.github.io/react-native-testing-library/)
- [Testing React Hooks](https://react-hooks-testing-library.com/)

---

## ✅ Pre-Merge Checklist

Before creating a PR:
- [ ] All tests pass (`npm test`)
- [ ] Coverage doesn't drop (`npm run test:coverage`)
- [ ] New code has tests
- [ ] No skipped/disabled tests
- [ ] Tests are meaningful (not just for coverage)

---

**Remember**: Tests are documentation. Write tests that explain what your code does and why.
