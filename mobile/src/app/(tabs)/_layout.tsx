import React from 'react';
import { useTranslation } from 'react-i18next';

import { Tabs } from '@/components/navigation/native-tabs';

export default function TabLayout() {
  const { t } = useTranslation();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: t('tabs.home'),
          tabBarIcon: () => ({ sfSymbol: 'house.fill' }),
        }}
      />
      <Tabs.Screen
        name="explore"
        options={{
          title: t('tabs.heartbeat'),
          tabBarIcon: () => ({ sfSymbol: 'heart.fill' }),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: t('settings.title'),
          tabBarIcon: () => ({ sfSymbol: 'gearshape.fill' }),
        }}
      />
    </Tabs>
  );
}
