module Main where

import Control.Applicative
import Control.Monad
import Criterion.Main
import System.Random.MWC

import qualified System.Random.MWC.Monad as MWCMonad

import qualified Data.Vector         as V
import qualified Data.Vector.Unboxed as U
import Math.Probable

probable3 :: (U.Unbox a, Variate a) => Int -> IO (U.Vector a)
probable3 n = mwc (vectorOf3 n)
{-# INLINE probable3 #-}

probable5 :: U.Unbox a => Int -> RandT IO a -> IO (U.Vector a)
probable5 n gen = mwc (vectorOf5 n gen)
{-# INLINE probable5 #-}

mwc1 :: (U.Unbox a, Variate a) => Int -> IO (U.Vector a)
mwc1 n = 
  withSystemRandom . asGenIO $ 
      \gen -> uniformVector gen n
{-# INLINE mwc1 #-}

mwc2 :: (U.Unbox a, Variate a) => Int -> IO (U.Vector a)
mwc2 n =
  withSystemRandom . asGenIO $
      \gen -> U.replicateM n (uniform gen)
{-# INLINE mwc2 #-}

mwcm :: (U.Unbox a, Variate a) => Int -> IO (U.Vector a)
mwcm n = 
  MWCMonad.runWithSystemRandom . MWCMonad.asRandIO $
      MWCMonad.toRand (flip uniformVector n)
{-# INLINE mwcm #-}

{-
-- | Dummy 'Person' type
data Person = Person 
    { age    :: Int
    , weight :: Double
    , salary :: Int
    } deriving (Eq, Show)

person :: (Generator g m Double, Generator g m Int) 
       => RandT g m Person
person = 
    Person <$> sampleUniform (1, 100)
           <*> sampleUniform (2, 130)
           <*> sampleUniform (500, 10000)

randomPersons :: Int -> IO (V.Vector Person)
randomPersons n = mwc (vectorOf n person)
-}

n :: Int
n = 10000000

-- | Time to benchmark!
main :: IO ()
main = do 
    defaultMain 
        [ 
            bgroup "big vector of int"
                [ bench "probable3" $ whnfIO (i $ probable3 n)
                , bench "probable5" $ whnfIO (probable5 n int)
                , bench "mwc-random" $ whnfIO (i $ mwc1 n)
                , bench "mwc-random2" $ whnfIO (i $ mwc2 n)
                , bench "mwc-random-monad2" $ whnfIO (i $ mwcm n)
                ],

            bgroup "big vector of double"
                [ bench "probable3" $ whnfIO (d $ probable3 n)
                , bench "probable5" $ whnfIO (probable5 n double)
                , bench "mwc-random" $ whnfIO (d $ mwc1 n)
                , bench "mwc-random2" $ whnfIO (d $ mwc2 n)
                , bench "mwc-random-monad2" $ whnfIO (d $ mwcm n)
                ]
        ]

d :: IO (U.Vector Double) -> IO (U.Vector Double)
d = id

i :: IO (U.Vector Int) -> IO (U.Vector Int)
i = id