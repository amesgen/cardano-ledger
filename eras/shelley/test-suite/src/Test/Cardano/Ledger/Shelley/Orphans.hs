{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Test.Cardano.Ledger.Shelley.Orphans () where

import qualified Cardano.Crypto.DSIGN as DSIGN
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Crypto (DSIGN)
import Cardano.Ledger.Keys
import Cardano.Ledger.PParams
import Cardano.Ledger.Pretty (PrettyA)
import Test.Cardano.Ledger.Shelley.Utils (Split (..))
import Data.Functor.Identity (Identity)
import Data.Maybe.Strict (StrictMaybe)
import Data.TreeDiff.Class (ToExpr (..))
import Generic.Random (genericArbitraryU)
import Test.QuickCheck (Arbitrary (..))

-- We need this here for the tests, but should not be in the actual library because
-- a Num instance for this type does not make sense in the general case.
deriving instance Num (DSIGN.VerKeyDSIGN (DSIGN c)) => Num (VKey kd c)

-- ===============================================================================
-- Generating random transactions requires splitting Values into multiple Values
-- with the same underlying amount of Coin. This property is crucial to generating
-- transactions which have the preservation of ADA property. (vsplit n v) breaks
-- v into n different values, and one remainder Coin, where the sum of the Coin
-- in the original value, and the sum of the underlying Coin in the list plus the
-- remainder coin are equal.
-- Given:    let (vs,coin) = split n value
-- Then:     (coin value) == sum(map coin vs) <+> coin

-- We introduce a new class Split which supplies this operation.
-- As new kinds of values become instances of the Val class, and we want to generate
-- transactions over these values, we will have to add additional instances here.

instance Split Coin where
  vsplit (Coin n) 0 = ([], Coin n)
  vsplit (Coin n) m
    | m Prelude.<= 0 = error "must split coins into positive parts"
    | otherwise = (take (fromIntegral m) (repeat (Coin (n `div` m))), Coin (n `rem` m))

-- ============================================================

instance ToExpr Coin

instance Arbitrary (PParamsHKD Identity era) => Arbitrary (PParams era) where
  arbitrary = genericArbitraryU

instance Arbitrary (PParamsHKD StrictMaybe era) => Arbitrary (PParamsUpdate era) where
  arbitrary = genericArbitraryU

deriving instance PrettyA (PParamsHKD Identity era) => PrettyA (PParams era)

deriving instance PrettyA (PParamsHKD StrictMaybe era) => PrettyA (PParamsUpdate era)
