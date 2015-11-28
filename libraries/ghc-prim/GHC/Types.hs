{-# LANGUAGE MagicHash, NoImplicitPrelude, TypeFamilies, UnboxedTuples,
             MultiParamTypeClasses, RoleAnnotations, CPP, TypeOperators #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  GHC.Types
-- Copyright   :  (c) The University of Glasgow 2009
-- License     :  see libraries/ghc-prim/LICENSE
--
-- Maintainer  :  cvs-ghc@haskell.org
-- Stability   :  internal
-- Portability :  non-portable (GHC Extensions)
--
-- GHC type definitions.
-- Use GHC.Exts from the base package instead of importing this
-- module directly.
--
-----------------------------------------------------------------------------

module GHC.Types (
        -- Data types that are built-in syntax
        -- They are defined here, but not explicitly exported
        --
        --    Lists:          []( [], (:) )
        --    Type equality:  (~)( Eq# )

        Bool(..), Char(..), Int(..), Word(..),
        Float(..), Double(..),
        Ordering(..), IO(..),
        isTrue#,
        SPEC(..),
        Nat, Symbol,
        type (~~), HCoercible,
        TYPE, Levity(..), Type, type (*), type (★), Constraint,
          -- The historical type * should ideally be written as
          -- `type *`, without the parentheses. But that's a true
          -- pain to parse, and for little gain.

        -- * Runtime type representation
        Module(..), TrName(..), TyCon(..)
    ) where

import GHC.Prim

infixr 5 :

{- *********************************************************************
*                                                                      *
                  Kinds
*                                                                      *
********************************************************************* -}

-- | The kind of constraints, like @Show a@
data Constraint

-- | The kind of types with values. For example @Int :: Type@.
type Type = TYPE 'Lifted

-- | A backward-compatible (pre-GHC 8.0) synonym for 'Type'
type * = TYPE 'Lifted

-- | A unicode backward-compatible (pre-GHC 8.0) synonym for 'Type'
type ★ = TYPE 'Lifted

{- *********************************************************************
*                                                                      *
                  Nat and Symbol
*                                                                      *
********************************************************************* -}

-- | (Kind) This is the kind of type-level natural numbers.
data Nat

-- | (Kind) This is the kind of type-level symbols.
-- Declared here because class IP needs it
data Symbol

{- *********************************************************************
*                                                                      *
                  Lists

   NB: lists are built-in syntax, and hence not explicitly exported
*                                                                      *
********************************************************************* -}

data [] a = [] | a : [a]


{- *********************************************************************
*                                                                      *
                  Ordering
*                                                                      *
********************************************************************* -}

data Ordering = LT | EQ | GT


{- *********************************************************************
*                                                                      *
                  Int, Char, Word, Float, Double
*                                                                      *
********************************************************************* -}

{- | The character type 'Char' is an enumeration whose values represent
Unicode (or equivalently ISO\/IEC 10646) characters (see
<http://www.unicode.org/> for details).  This set extends the ISO 8859-1
(Latin-1) character set (the first 256 characters), which is itself an extension
of the ASCII character set (the first 128 characters).  A character literal in
Haskell has type 'Char'.

To convert a 'Char' to or from the corresponding 'Int' value defined
by Unicode, use 'Prelude.toEnum' and 'Prelude.fromEnum' from the
'Prelude.Enum' class respectively (or equivalently 'ord' and 'chr').
-}
data {-# CTYPE "HsChar" #-} Char = C# Char#

-- | A fixed-precision integer type with at least the range @[-2^29 .. 2^29-1]@.
-- The exact range for a given implementation can be determined by using
-- 'Prelude.minBound' and 'Prelude.maxBound' from the 'Prelude.Bounded' class.
data {-# CTYPE "HsInt" #-} Int = I# Int#

-- |A 'Word' is an unsigned integral type, with the same size as 'Int'.
data {-# CTYPE "HsWord" #-} Word = W# Word#

-- | Single-precision floating point numbers.
-- It is desirable that this type be at least equal in range and precision
-- to the IEEE single-precision type.
data {-# CTYPE "HsFloat" #-} Float = F# Float#

-- | Double-precision floating point numbers.
-- It is desirable that this type be at least equal in range and precision
-- to the IEEE double-precision type.
data {-# CTYPE "HsDouble" #-} Double = D# Double#


{- *********************************************************************
*                                                                      *
                    IO
*                                                                      *
********************************************************************* -}

{- |
A value of type @'IO' a@ is a computation which, when performed,
does some I\/O before returning a value of type @a@.

There is really only one way to \"perform\" an I\/O action: bind it to
@Main.main@ in your program.  When your program is run, the I\/O will
be performed.  It isn't possible to perform I\/O from an arbitrary
function, unless that function is itself in the 'IO' monad and called
at some point, directly or indirectly, from @Main.main@.

'IO' is a monad, so 'IO' actions can be combined using either the do-notation
or the '>>' and '>>=' operations from the 'Monad' class.
-}
newtype IO a = IO (State# RealWorld -> (# State# RealWorld, a #))
type role IO representational

{- The 'type role' role annotation for IO is redundant but is included
because this role is significant in the normalisation of FFI
types. Specifically, if this role were to become nominal (which would
be very strange, indeed!), changes elsewhere in GHC would be
necessary. See [FFI type roles] in TcForeign.  -}


{- *********************************************************************
*                                                                      *
                    (~) and Coercible

   NB: (~) is built-in syntax, and hence not explicitly exported
*                                                                      *
********************************************************************* -}

{-
Note [Kind-changing of (~) and Coercible]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

(~) and Coercible are tricky to define. To the user, they must appear as
constraints, but we cannot define them as such in Haskell. But we also cannot
just define them only in GHC.Prim (like (->)), because we need a real module
for them, e.g. to compile the constructor's info table.

Furthermore the type of MkCoercible cannot be written in Haskell
(no syntax for ~#R).

So we define them as regular data types in GHC.Types, and do magic in TysWiredIn,
inside GHC, to change the kind and type.
-}


-- | Lifted, heterogeneous equality. By lifted, we mean that it
-- can be bogus (deferred type error). By heterogeneous, the two
-- types @a@ and @b@ might have different kinds.
class a ~~ b

-- | Lifted, heterogeneous, representational equality. By lifted, we mean that it
-- can be bogus (deferred type error). By heterogeneous, the two
-- types @a@ and @b@ might have different kinds. See also 'Data.Coerce.Coercible'.
class HCoercible a b

-- | Alias for 'tagToEnum#'. Returns True if its parameter is 1# and False
--   if it is 0#.

{- *********************************************************************
*                                                                      *
                   Bool, and isTrue#
*                                                                      *
********************************************************************* -}

data {-# CTYPE "HsBool" #-} Bool = False | True

{-# INLINE isTrue# #-}
isTrue# :: Int# -> Bool   -- See Note [Optimizing isTrue#]
isTrue# x = tagToEnum# x

{- Note [Optimizing isTrue#]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Current definition of isTrue# is a temporary workaround. We would like to
have functions isTrue# and isFalse# defined like this:

    isTrue# :: Int# -> Bool
    isTrue# 1# = True
    isTrue# _  = False

    isFalse# :: Int# -> Bool
    isFalse# 0# = True
    isFalse# _  = False

These functions would allow us to safely check if a tag can represent True
or False. Using isTrue# and isFalse# as defined above will not introduce
additional case into the code. When we scrutinize return value of isTrue#
or isFalse#, either explicitly in a case expression or implicitly in a guard,
the result will always be a single case expression (given that optimizations
are turned on). This results from case-of-case transformation. Consider this
code (this is both valid Haskell and Core):

case isTrue# (a ># b) of
    True  -> e1
    False -> e2

Inlining isTrue# gives:

case (case (a ># b) of { 1# -> True; _ -> False } ) of
    True  -> e1
    False -> e2

Case-of-case transforms that to:

case (a ># b) of
  1# -> case True of
          True  -> e1
          False -> e2
  _  -> case False of
          True  -> e1
          False -> e2

Which is then simplified by case-of-known-constructor:

case (a ># b) of
  1# -> e1
  _  -> e2

While we get good Core here, the code generator will generate very bad Cmm
if e1 or e2 do allocation. It will push heap checks into case alternatives
which results in about 2.5% increase in code size. Until this is improved we
just make isTrue# an alias to tagToEnum#. This is a temporary solution (if
you're reading this in 2023 then things went wrong). See #8326.
-}


{- *********************************************************************
*                                                                      *
                    SPEC
*                                                                      *
********************************************************************* -}

-- | 'SPEC' is used by GHC in the @SpecConstr@ pass in order to inform
-- the compiler when to be particularly aggressive. In particular, it
-- tells GHC to specialize regardless of size or the number of
-- specializations. However, not all loops fall into this category.
--
-- Libraries can specify this by using 'SPEC' data type to inform which
-- loops should be aggressively specialized.
data SPEC = SPEC | SPEC2

-- | GHC divides all proper types (that is, types that can perhaps be
-- inhabited, as distinct from type constructors or type-level data)
-- into two worlds: lifted types and unlifted types. For example,
-- @Int@ is lifted while @Int#@ is unlifted. Certain operations need
-- to be polymorphic in this distinction. A classic example is 'unsafeCoerce#',
-- which needs to be able to coerce between lifted and unlifted types.
-- To achieve this, we use kind polymorphism: lifted types have kind
-- @TYPE Lifted@ and unlifted ones have kind @TYPE Unlifted@. 'Levity'
-- is the kind of 'Lifted' and 'Unlifted'. @*@ is a synonym for @TYPE Lifted@
-- and @#@ is a synonym for @TYPE Unlifted@.
data Levity = Lifted | Unlifted

{- *********************************************************************
*                                                                      *
             Runtime represntation of TyCon
*                                                                      *
********************************************************************* -}

{- Note [Runtime representation of modules and tycons]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We generate a binding for M.$modName and M.$tcT for every module M and
data type T.  Things to think about

  - We want them to be economical on space; ideally pure data with no thunks.

  - We do this for every module (except this module GHC.Types), so we can't
    depend on anything else (eg string unpacking code)

That's why we have these terribly low-level repesentations.  The TrName
type lets us use the TrNameS constructor when allocating static data;
but we also need TrNameD for the case where we are deserialising a TyCon
or Module (for example when deserialising a TypeRep), in which case we
can't conveniently come up with an Addr#.


Note [Representations of types defined in GHC.Types]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The representations for the types defined in GHC.Types are
defined in GHC.Typeable.Internal.

-}

#include "MachDeps.h"

data Module = Module
                TrName   -- Package name
                TrName   -- Module name

data TrName
  = TrNameS Addr#  -- Static
  | TrNameD [Char] -- Dynamic

#if WORD_SIZE_IN_BITS < 64
data TyCon = TyCon
                Word64#  Word64#   -- Fingerprint
                Module             -- Module in which this is defined
                TrName              -- Type constructor name
#else
data TyCon = TyCon
                Word#    Word#
                Module
                TrName
#endif
