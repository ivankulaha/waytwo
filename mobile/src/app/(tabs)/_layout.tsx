import { Tabs } from 'expo-router';
import React from 'react';
import { useTranslation } from 'react-i18next';

import { HapticTab } from '@/components/haptic-tab';
import { IconSymbol } from '@/components/ui/icon-symbol';
import { Size } from '@/constants/tokens';
import { useColorSchemeResolved } from '@/hooks/use-color-scheme-resolved';

/** TODO(legacy-template): Delete with new tab/home redesign — not part of AppColors. */
const TEMPORARY_TAB_BAR_COLORS = {
  light: { tint: '#0a7ea4', background: '#fff' },
  dark: { tint: '#fff', background: '#151718' },
} as const;

export default function TabLayout() {
  const { t } = useTranslation();
  const scheme = useColorSchemeResolved();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: TEMPORARY_TAB_BAR_COLORS[scheme].tint,
        headerShown: false,
        tabBarButton: HapticTab,
        tabBarStyle: { backgroundColor: TEMPORARY_TAB_BAR_COLORS[scheme].background },
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: t('tabs.home'),
          tabBarIcon: ({ color }) => (
            <IconSymbol size={Size.tabBarIcon} name="house.fill" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="explore"
        options={{
          title: t('tabs.explore'),
          tabBarIcon: ({ color }) => (
            <IconSymbol size={Size.tabBarIcon} name="paperplane.fill" color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
