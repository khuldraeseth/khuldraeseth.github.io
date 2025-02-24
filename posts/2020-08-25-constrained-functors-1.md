---
title: Constrained Functors, part 1
---

I follow [r/haskell](https://reddit.com/r/haskell) on Reddit, and there was a post this afternoon that caught my eye: [Why aren’t (Hash)Sets Functors?](https://www.reddit.com/r/haskell/comments/igk7hv/why_arent_hashsets_functors) The title really says it all—why is [`Data.Set.map`](https://hackage.haskell.org/package/containers-0.6.3.1/docs/Data-Set.html#v:map) not sufficient to provide a Functor instance for [`Data.Set.Set`](https://hackage.haskell.org/package/containers-0.6.3.1/docs/Data-Set.html#t:Set)?

A [response](https://www.reddit.com/r/haskell/comments/igk7hv/why_arent_hashsets_functors/g2u82y0) from u/Lalaithion42 says it succinctly. `fmap` and `Data.Set.map` look similar in type, but they differ in their constraints. This makes sense—a `Functor` allows mapping using an arbitrary function `f :: a -> b`, which obviously won’t work on an ordered set. There’s no requirement here that `b` even be orderable, so what would "ordered set" even mean? And even if we fortuitously have `Ord b`, there’s no guarantee the resulting "set" will even be that unless our function `f` is [increasing](https://hackage.haskell.org/package/containers-0.6.3.1/docs/Data-Set.html#v:mapMonotonic).

```haskell
fmap  :: (Functor f) => (a -> b) -> f a     -> f b
S.map :: (Ord b)     => (a -> b) -> S.Set a -> S.Set b
```

So sets are not functors. But clearly they can be reasonably mapped over under a certain condition—namely, the image type of the map must be orderable. Now, loving Haskell as I do, I decided it would be almost a crime to let this go without at least trying to figure out some abstraction for this notion. Thus was class `ConstrainedFunctor` born.

```haskell
{-# LANGUAGE AllowAmbiguousTypes   #-}
{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE MultiParamTypeClasses #-}

import Data.Kind

class ConstrainedFunctor (c :: Type -> Constraint) (f :: Type -> Type) where
    cfmap :: (c b) => (a -> b) -> f a -> f b
```

`ConstrainedFunctor c` is the class of types over which we can map any function `(c b) => a -> b`. In our `S.Set` example, we need `Ord`, so let’s try to write this instance:

```haskell
instance ConstrainedFunctor Ord S.Set where
    cfmap = S.map
```

Very nice. And trying it out in GHCi works almost as expected:

```haskell
λ> S.fromList [-3 .. 6]
fromList [-3,-2,-1,0,1,2,3,4,5,6]
it :: (Ord a, Num a, Enum a) => S.Set a
λ> cfmap (^2) it

<interactive>:2:1: error:
    • Illegal constraint: c b (Use ConstraintKinds to permit this)
    • When checking the inferred type
        it :: forall (c :: * -> Constraint) b.
              (c b, ConstrainedFunctor c S.Set, Num b, Ord b, Enum b) =>
              S.Set b

λ> :set -XTypeApplications
λ> cfmap @Ord (^2) it
fromList [0,1,4,9,16,25,36]
it :: (Num b, Ord b, Enum b) => S.Set b
```

We need the `TypeApplications` extension enabled to tell the compiler which `ConstrainedFunctor` instance we’re taking `cfmap` from, as one type could reasonably have more than one such instance. I think; this is all still pretty spooky to a not-quite-beginner like me.

Now, any `Functor` is also a `ConstrainedFunctor c` for all `c`. Let’s put this to code:

```haskell
{-# LANGUAGE FlexibleInstances #-}

instance (Functor f) => ConstrainedFunctor c f where
    fmap = cfmap
```

This compiles fine, but attempting to use it now fails! `cfmap @Ord (^2) it` complains about overlapping instances for `ConstrainedFunctor Ord S.Set`:

```haskell
Matching instances:
    instance [safe] Functor f => ConstrainedFunctor c f
    instance [safe] ConstrainedFunctor Ord Set
```

Interesting. `S.Set` is no `Functor`, so why in the world is that first instance a candidate? Some thought on my part yielded nothing (admittedly, it is past 11 PM). So I turned to a bottom-up view of this relationship rather than a top-down one.

```haskell
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UndecidableInstances #-} -- uh-oh

class Yes a
instance Yes a

instance (ConstrainedFunctor Yes f) => Functor f where
    cfmap = fmap @Yes
```

And this one works! For the set example from before, at least. Sure, `UndecidableInstances` is pretty ugly (or so I’ve heard), but it scares me less than the deprecated `OverlappingInstances` and per-instance pragmas I’m supposed to use instead.

Might as well implement a few `Functor` instances using this always-satisfied `Yes` constraint, huh?

```haskell
instance ConstrainedFunctor Yes Maybe where
    cfmap f mx = case mx of
        Nothing -> Nothing
        Just x -> Just (f x)

instance ConstrainedFunctor Yes [] where
    cfmap = map
```

Everything still compiles, nice! Now, attempting to use either `Functor` instance will give us an error thanks to overlapping instances, and for good reason this time. But that’s not a fault of the code—this should be pretty easily remedied by simply using a new but identical typeclass instead of `Data.Functor.Functor`.

The clock approaches midnight. I’ll call it a post here. Gonna try to put some more thought toward that top-down view, and should I get nowhere there, I’ll see what from `base` I can translate to this `ConstrainedFunctor`. That’ll be part 2.
