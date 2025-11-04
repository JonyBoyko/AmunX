import { useState, useEffect } from 'react';
import { Alert } from 'react-native';
import type { PurchasesPackage, PurchasesOffering, CustomerInfo } from 'react-native-purchases';

import {
  getOfferings,
  purchasePackage,
  restorePurchases,
  getCustomerInfo,
  isPro as checkIsPro,
} from '@services/revenueCat';

export function useRevenueCat() {
  const [offerings, setOfferings] = useState<PurchasesOffering | null>(null);
  const [isPro, setIsPro] = useState(false);
  const [loading, setLoading] = useState(true);
  const [purchasing, setPurchasing] = useState(false);

  useEffect(() => {
    loadOfferings();
    checkProStatus();
  }, []);

  const loadOfferings = async () => {
    try {
      setLoading(true);
      const currentOffering = await getOfferings();
      setOfferings(currentOffering);
    } catch (error) {
      console.error('Failed to load offerings:', error);
    } finally {
      setLoading(false);
    }
  };

  const checkProStatus = async () => {
    try {
      const proStatus = await checkIsPro();
      setIsPro(proStatus);
    } catch (error) {
      console.error('Failed to check PRO status:', error);
    }
  };

  const purchase = async (pkg: PurchasesPackage): Promise<boolean> => {
    try {
      setPurchasing(true);
      const customerInfo: CustomerInfo = await purchasePackage(pkg);
      
      // Check if user now has PRO entitlement
      const hasProEntitlement = customerInfo.entitlements.active['pro'] !== undefined;
      setIsPro(hasProEntitlement);

      return hasProEntitlement;
    } catch (error: any) {
      if (!error.userCancelled) {
        Alert.alert('Purchase Failed', error?.message || 'Please try again');
      }
      return false;
    } finally {
      setPurchasing(false);
    }
  };

  const restore = async (): Promise<boolean> => {
    try {
      setPurchasing(true);
      const customerInfo = await restorePurchases();
      
      // Check if user has PRO entitlement after restore
      const hasProEntitlement = customerInfo.entitlements.active['pro'] !== undefined;
      setIsPro(hasProEntitlement);

      if (hasProEntitlement) {
        Alert.alert('Success', 'Your purchases have been restored!');
      } else {
        Alert.alert('No Purchases Found', 'We could not find any purchases to restore');
      }

      return hasProEntitlement;
    } catch (error: any) {
      Alert.alert('Restore Failed', error?.message || 'Please try again');
      return false;
    } finally {
      setPurchasing(false);
    }
  };

  return {
    offerings,
    isPro,
    loading,
    purchasing,
    purchase,
    restore,
    refresh: () => {
      loadOfferings();
      checkProStatus();
    },
  };
}

