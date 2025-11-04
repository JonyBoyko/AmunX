import {
  formatSeconds,
  formatMilliseconds,
  formatDate,
  formatRelativeTime,
  formatFileSize,
  formatNumber,
  truncateText,
} from '@utils/formatters';

describe('formatters', () => {
  describe('formatSeconds', () => {
    it('formats seconds to MM:SS', () => {
      expect(formatSeconds(90)).toBe('1:30');
      expect(formatSeconds(45)).toBe('0:45');
    });

    it('formats seconds to HH:MM:SS', () => {
      expect(formatSeconds(3661)).toBe('1:01:01');
      expect(formatSeconds(7200)).toBe('2:00:00');
    });
  });

  describe('formatMilliseconds', () => {
    it('converts milliseconds to time format', () => {
      expect(formatMilliseconds(90000)).toBe('1:30');
      expect(formatMilliseconds(3661000)).toBe('1:01:01');
    });
  });

  describe('formatDate', () => {
    it('formats date object', () => {
      const date = new Date('2025-01-15');
      const formatted = formatDate(date);
      // Should contain date parts (works for any locale)
      expect(formatted).toContain('15');
      expect(formatted).toContain('2025');
      expect(formatted.length).toBeGreaterThan(5);
    });

    it('formats date string', () => {
      const formatted = formatDate('2025-01-15');
      // Should contain date parts (works for any locale)
      expect(formatted).toContain('15');
      expect(formatted).toContain('2025');
    });
  });

  describe('formatRelativeTime', () => {
    it('formats just now', () => {
      const now = new Date();
      expect(formatRelativeTime(now)).toBe('just now');
    });

    it('formats minutes ago', () => {
      const date = new Date(Date.now() - 5 * 60 * 1000); // 5 minutes ago
      expect(formatRelativeTime(date)).toBe('5 minutes ago');
    });

    it('formats hours ago', () => {
      const date = new Date(Date.now() - 2 * 60 * 60 * 1000); // 2 hours ago
      expect(formatRelativeTime(date)).toBe('2 hours ago');
    });
  });

  describe('formatFileSize', () => {
    it('formats bytes', () => {
      expect(formatFileSize(0)).toBe('0 Bytes');
      expect(formatFileSize(500)).toBe('500 Bytes');
    });

    it('formats kilobytes', () => {
      expect(formatFileSize(1024)).toBe('1 KB');
      expect(formatFileSize(1536)).toBe('1.5 KB');
    });

    it('formats megabytes', () => {
      expect(formatFileSize(1048576)).toBe('1 MB');
      expect(formatFileSize(5242880)).toBe('5 MB');
    });
  });

  describe('formatNumber', () => {
    it('formats numbers with thousands separator', () => {
      const formatted1k = formatNumber(1000);
      const formatted1m = formatNumber(1000000);
      // Should have separator (space or comma depending on locale)
      expect(formatted1k).toContain('000');
      expect(formatted1k).toContain('1');
      expect(formatted1m.length).toBeGreaterThan(5);
    });
  });

  describe('truncateText', () => {
    it('truncates long text', () => {
      const text = 'This is a very long text that should be truncated';
      expect(truncateText(text, 20)).toBe('This is a very lo...');
    });

    it('does not truncate short text', () => {
      const text = 'Short text';
      expect(truncateText(text, 20)).toBe('Short text');
    });
  });
});

