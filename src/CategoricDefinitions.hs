{-# LANGUAGE 
             EmptyCase,
             FlexibleInstances,
             FlexibleContexts,
             InstanceSigs,
             MultiParamTypeClasses,
             PartialTypeSignatures,
             LambdaCase,
             MultiWayIf,
             NamedFieldPuns,
             TupleSections,
             DeriveFunctor,
             TypeOperators,
             ScopedTypeVariables,
             ConstraintKinds,
             RankNTypes,
             NoMonomorphismRestriction,
             TypeFamilies,
             UndecidableInstances,
             GeneralizedNewtypeDeriving
                            #-}

module CategoricDefinitions where

import Prelude hiding (id, (.))
import qualified Prelude as P
import GHC.Exts (Constraint)

class Category k where
  type Allowed k a :: Constraint
  type Allowed k a = ()

  id  :: Allowed k a => a `k` a
  (.) :: Allowed3 k a b c => (b `k` c) -> (a `k` b) -> (a `k` c)

-- By monoidal here we mean symmetric monoidal category
class Category k => Monoidal k where
  x :: Allowed6 k a b c d (a, b) (c, d) => (a `k` c) -> (b `k` d) -> ((a, b) `k` (c, d))
  assocL :: Allowed3 k a b c => ((a, b), c) `k` (a, (b, c))
  assocR :: Allowed3 k a b c => (a, (b, c)) `k` ((a, b), c)
  swap :: Allowed2 k a b => (a, b) `k` (b, a)

class Monoidal k => Cartesian k where
  type AllowedCar k a :: Constraint
  type AllowedCar k a = ()

  exl :: AllowedCar k b => (a, b) `k` a
  exr :: AllowedCar k a => (a, b) `k` b
  dup :: AllowedCar k a => a `k` (a, a)

class Category k => Cocartesian k where
  type AllowedCoCar k a :: Constraint
  type AllowedCoCar k a = Allowed k a

  inl :: AllowedCoCar k b => a `k` (a, b)
  inr :: AllowedCoCar k a => b `k` (a, b)
  jam :: AllowedCoCar k a => (a, a) `k` a

--(/\) :: (Cartesian k, Allowed k b, Allowed k (b, b), Allowed k (c, d))
--     => b `k` c -> b `k` d -> b `k` (c, d)
f /\ g = (f `x` g) . dup 

--(\/) :: (Cocartesian k, Monoidal k, Allowed k (a, b), Allowed k (c, c), Allowed k c)
--     => a `k` c -> b `k` c -> (a, b) `k` c
f \/ g = jam . (f `x` g)

--fork :: (Cartesian k, Allowed k b, Allowed k (b, b), Allowed k (c, d))
--     => (b `k` c,  b `k` d) -> b `k` (c, d)
fork (f, g) = f /\ g

--unfork :: (Cartesian k, Allowed k b, Allowed k (c, d), Allowed k c, Allowed k d)
--       => b `k` (c, d) -> (b `k` c, b `k` d)
unfork h = (exl . h, exr . h)

--join :: (Cocartesian k, Monoidal k, Allowed k (a, b), Allowed k (c, c), Allowed k c) 
--     => (a `k` c, b `k` c) -> (a, b) `k` c
join (f, g) = f \/ g

--unjoin :: (Cocartesian k, Monoidal k, Allowed k a, Allowed k (a, b), Allowed k c, Allowed k b)
--       => (a, b) `k` c -> (a `k` c, b `k` c) 
unjoin h = (h . inl, h . inr)

--------------------------------------


class NumCat k a where
  negateC :: a `k` a
  addC :: (a, a) `k` a
  mulC :: (a, a) `k` a

class FloatCat k a where
  expC :: a `k` a

class Scalable k a where
  scale :: a -> (a `k` a)

class Additive a where
  zero :: a
  (^+) :: a -> a -> a

-------------------------------------
-- Instances
-------------------------------------

instance Category (->) where
  id    = \a -> a
  g . f = \a -> g (f a)

instance Monoidal (->) where
  f `x` g = \(a, b) -> (f a, g b)
  assocL = \((a, b), c) -> (a, (b, c))
  assocR = \(a, (b, c)) -> ((a, b), c)
  swap = \(a, b) -> (b, a)

instance Cartesian (->) where
  exl = \(a, _) -> a
  exr = \(_, b) -> b
  dup = \a -> (a, a)

instance Num a => NumCat (->) a where
  negateC = negate
  addC = uncurry (+)
  mulC = uncurry (*)

instance Floating a => FloatCat (->) a where
  expC = exp


-------------------------------------

instance {-# OVERLAPS #-} (Num a) => Additive a where
  zero = 0
  (^+) = (+)

instance {-# OVERLAPS #-} (Additive a, Additive b) => Additive (a, b) where
  zero = (zero, zero)
  (a1, b1) ^+ (a2, b2) = (a1 ^+ a2, b1 ^+ b2)


inlF :: Additive b => a -> (a, b)
inrF :: Additive a => b -> (a, b)
jamF :: Additive a => (a, a) -> a

inlF = \a -> (a, zero)
inrF = \b -> (zero, b)
jamF = \(a, b) -> a ^+ b

-------------------------------------

type Allowed2 k a b = (Allowed k a, Allowed k b)
type Allowed3 k a b c = (Allowed2 k a b, Allowed k c)
type Allowed4 k a b c d = (Allowed3 k a b c, Allowed k d)
type Allowed5 k a b c d e = (Allowed4 k a b c d, Allowed k e)
type Allowed6 k a b c d e f = (Allowed5 k a b c d e, Allowed k f)

type Additive2 a b = (Additive a, Additive b)
type Additive3 a b c = (Additive2 a b, Additive c)
type Additive4 a b c d = (Additive3 a b c, Additive d)
type Additive5 a b c d e = (Additive4 a b c d, Additive e)
type Additive6 a b c d e f = (Additive5 a b c d e, Additive f)
type Additive7 a b c d e f g = (Additive6 a b c d e f, Additive g)
type Additive8 a b c d e f g h = (Additive7 a b c d e f g, Additive h)
type Additive9 a b c d e f g h i = (Additive8 a b c d e f g h , Additive i)
