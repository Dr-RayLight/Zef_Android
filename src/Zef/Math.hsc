{-# LANGUAGE CPP                      #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module Zef.Math where

import Foreign.C.Types
import Foreign.Ptr
import System.IO.Unsafe
import Control.Monad
import Prelude  hiding (div)

import Zef.Internal.Types
import Zef.Internal.Image
import Zef.Image

#include <zef_core.h>
#include <opencv2/core/core_c.h>

foreign import ccall unsafe "core_c.h cvAdd"
    c_cvAdd' :: PCvMat -> PCvMat -> PCvMat -> PCvMat -> IO ()

c_cvAdd :: BinaryImageOp
c_cvAdd srcA srcB dst = c_cvAdd' srcA srcB dst nullPtr

add :: Image a => a -> a -> a
add = performBinaryOp c_cvAdd

(.+) :: Image a => a -> a -> a
(.+) = add

foreign import ccall unsafe "core_c.h cvSub"
    c_cvSub' :: PCvMat -> PCvMat -> PCvMat -> PCvMat -> IO ()

c_cvSub :: BinaryImageOp
c_cvSub srcA srcB dst = c_cvSub' srcA srcB dst nullPtr

sub :: Image a => a -> a -> a
sub = performBinaryOp c_cvSub

(.-) :: Image a => a -> a -> a
(.-) = sub

foreign import ccall unsafe "core_c.h cvMul"
    c_cvMul :: PCvMat -> PCvMat -> PCvMat -> CDouble -> IO ()

mul :: Image a => a -> a -> a
mul = performBinaryOp $ \pSrcA pSrcB pDst -> c_cvMul pSrcA pSrcB pDst 1.0

(.*) :: Image a => a -> a -> a
(.*) = mul

foreign import ccall unsafe "core_c.h cvDiv"
    c_cvDiv :: PCvMat -> PCvMat -> PCvMat -> CDouble -> IO ()

div :: Image a => a -> a -> a
div = performBinaryOp $ \pSrcA pSrcB pDst -> c_cvDiv pSrcA pSrcB pDst 1.0

(./) :: Image a => a -> a -> a
(./) = div

foreign import ccall unsafe "core_c.h cvLaplace"
    c_cvLaplace :: PCvMat -> PCvMat -> CInt -> IO ()

laplacian :: Image a => a -> a
laplacian = performUnaryOp (\pSrc pDst -> c_cvLaplace pSrc pDst 3)

foreign import ccall unsafe "zef_core.h zef_abs"
    c_zef_abs :: UnaryImageOp

abs :: Image a => a -> a
abs = performUnaryOp c_zef_abs

foreign import ccall unsafe "core_c.h cvPow"
    c_cvPow :: PCvMat -> PCvMat -> CDouble -> IO ()

pow' :: Image a => CDouble -> a -> a
pow' e = performUnaryOp $ \pSrc pDst -> c_cvPow pSrc pDst e

pow :: Image a => a -> CDouble -> a
pow img e = pow' e img

(.^) :: Image a => a -> CDouble -> a
(.^) = pow

sqrt :: Image a => a -> a
sqrt = pow' 0.5

scale :: Image a => a -> CDouble -> a
scale img s = scaleConvertImage (imageDepth img) s img

(~*) :: Image a => a -> CDouble -> a
(~*) = scale

sum :: Image a => [a] -> a
sum images = unsafePerformIO $ do
    acc <- mkSimilarImage (images!!0)
    setImage acc 0
    withImagePtr acc $ \pAcc ->
        forM_ images $ \img ->
            withImagePtr img $ \pImg ->
                c_cvAdd pAcc pImg pAcc
    return acc

sumStacked :: Image a => [[a]] => [a]
sumStacked stacks = unsafePerformIO $ do
    stackOut <- mapM mkSimilarImage (stacks!!0)
    forM_ stackOut $ \img -> setImage img 0
    forM_ stacks $ \aStack ->
        forM_ (zip stackOut aStack) $ \(levelAcc, anImg) ->
            withImagePtr levelAcc $ \pLevelAcc ->
                withImagePtr anImg $ \pImg ->
                    c_cvAdd pLevelAcc pImg pLevelAcc
    return stackOut
