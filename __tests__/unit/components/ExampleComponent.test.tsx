/**
 * Example Component Test
 *
 * This demonstrates how to test React Native components using
 * React Native Testing Library.
 */

import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { Text, Pressable, View } from 'react-native';

// Example component to test
function SimpleButton({ onPress, title }: { onPress: () => void; title: string }) {
  return (
    <Pressable onPress={onPress}>
      <Text>{title}</Text>
    </Pressable>
  );
}

function Counter() {
  const [count, setCount] = React.useState(0);

  return (
    <View>
      <Text>Count: {count}</Text>
      <SimpleButton
        onPress={() => setCount(count + 1)}
        title="Increment"
      />
    </View>
  );
}

describe('SimpleButton', () => {
  it('renders button with title', () => {
    const { getByText } = render(<SimpleButton onPress={() => {}} title="Click Me" />);
    expect(getByText('Click Me')).toBeTruthy();
  });

  it('calls onPress when tapped', () => {
    const mockOnPress = jest.fn();
    const { getByText } = render(<SimpleButton onPress={mockOnPress} title="Test Button" />);

    fireEvent.press(getByText('Test Button'));
    expect(mockOnPress).toHaveBeenCalledTimes(1);
  });
});

describe('Counter', () => {
  it('starts with count of 0', () => {
    const { getByText } = render(<Counter />);
    expect(getByText('Count: 0')).toBeTruthy();
  });

  it('increments count when button pressed', () => {
    const { getByText } = render(<Counter />);

    const button = getByText('Increment');
    fireEvent.press(button);

    expect(getByText('Count: 1')).toBeTruthy();
  });

  it('increments multiple times', () => {
    const { getByText } = render(<Counter />);

    const button = getByText('Increment');
    fireEvent.press(button);
    fireEvent.press(button);
    fireEvent.press(button);

    expect(getByText('Count: 3')).toBeTruthy();
  });
});
