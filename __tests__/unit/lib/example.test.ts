/**
 * Example Unit Test - Utility Function
 *
 * This demonstrates how to write unit tests for pure functions.
 */

describe('Example Utility Tests', () => {
  describe('Math operations', () => {
    it('should add two numbers correctly', () => {
      const result = 2 + 2;
      expect(result).toBe(4);
    });

    it('should multiply numbers correctly', () => {
      const result = 3 * 4;
      expect(result).toBe(12);
    });
  });

  describe('String operations', () => {
    it('should concatenate strings', () => {
      const result = 'Hello' + ' ' + 'World';
      expect(result).toBe('Hello World');
    });

    it('should convert to uppercase', () => {
      const result = 'test'.toUpperCase();
      expect(result).toBe('TEST');
    });
  });
});
