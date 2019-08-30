import Prelude hiding (Monad)

data Monad = N
    deriving (Eq, Show)

data Dyad = A | C | E | K
    deriving (Eq, Show)

data Pred = PredN Char
          | PredM Monad Pred
          | PredD Dyad Pred Pred
    deriving (Eq, Show)

toStdM :: Monad -> String
toStdM N = "¬"

toStdD :: Dyad -> String
toStdD A = "∨"
toStdD C = "→"
toStdD E = "⇔"
toStdD K = "∧"

stdize :: Pred -> String
stdize (PredN c) = [c]
stdize (PredM m p) = toStdM m ++ "(" ++ stdize p ++ ")"
stdize (PredD d p q) = "(" ++ stdize p ++ ")" ++ toStdD d ++ "(" ++ stdize q ++ ")"

readS :: String -> [(Pred, String)]
readS "" = []
readS (x:xs) = case x of
                    'N' -> [(PredM N p, ys)] where (p, ys) = head $ readS xs
                    'A' -> [(PredD A p q, zs)] where (p, ys) = head $ readS xs
                                                     (q, zs) = head $ readS ys
                    'C' -> [(PredD C p q, zs)] where (p, ys) = head $ readS xs
                                                     (q, zs) = head $ readS ys
                    'E' -> [(PredD E p q, zs)] where (p, ys) = head $ readS xs
                                                     (q, zs) = head $ readS ys
                    'K' -> [(PredD K p q, zs)] where (p, ys) = head $ readS xs
                                                     (q, zs) = head $ readS ys
                    _   -> [(PredN x, xs)]

instance Read Pred where
    readsPrec = const readS

comp :: String -> String
comp = stdize . read