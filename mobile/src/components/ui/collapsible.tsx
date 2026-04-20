import { PropsWithChildren, useState } from 'react';
import { StyleSheet, TouchableOpacity } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { IconSymbol } from '@/components/ui/icon-symbol';
import { IconSize, Spacing } from '@/constants/tokens';
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';

/** TODO(legacy-template): Remove with explore / parallax demo screen. */
const TEMPORARY_COLLAPSE_ICON = { light: '#687076', dark: '#9BA1A6' } as const;

export function Collapsible({ children, title }: PropsWithChildren & { title: string }) {
  const [isOpen, setIsOpen] = useState(false);
  const scheme = useColorSchemeResolved();

  return (
    <ThemedView>
      <TouchableOpacity
        style={styles.heading}
        onPress={() => setIsOpen((value) => !value)}
        activeOpacity={0.8}>
        <IconSymbol
          name="chevron.right"
          size={IconSize.sm}
          weight="medium"
          color={TEMPORARY_COLLAPSE_ICON[scheme]}
          style={{ transform: [{ rotate: isOpen ? '90deg' : '0deg' }] }}
        />

        <ThemedText type="defaultSemiBold">{title}</ThemedText>
      </TouchableOpacity>
      {isOpen && <ThemedView style={styles.content}>{children}</ThemedView>}
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  heading: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  content: {
    marginTop: Spacing.sm,
    marginLeft: Spacing['3xl'],
  },
});
