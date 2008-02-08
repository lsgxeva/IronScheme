#region License
/* ****************************************************************************
 * Copyright (c) Llewellyn Pritchard. 
 *
 * This source code is subject to terms and conditions of the Microsoft Public License. 
 * A copy of the license can be found in the License.html file at the root of this distribution. 
 * By using this source code in any fashion, you are agreeing to be bound by the terms of the 
 * Microsoft Public License.
 *
 * You must not remove this notice, or any other, from this software.
 * ***************************************************************************/
#endregion

using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel;
using Microsoft.Scripting;
using System.Diagnostics;
using IronScheme.Compiler;
using Microsoft.Scripting.Ast;

namespace IronScheme.Runtime
{
  public static partial class BuiltinEmitters
  {
    [InlineEmitter("symbol?")]
    public static Expression IsSymbol(Expression[] obj)
    {
      return Ast.TypeIs(obj[0], typeof(SymbolId));
    }

    [InlineEmitter("boolean?")]
    public static Expression IsBoolean(Expression[] obj)
    {
      return Ast.TypeIs(obj[0], typeof(bool));
    }

    [InlineEmitter("procedure?")]
    public static Expression IsProcedure(Expression[] obj)
    {
      return Ast.TypeIs(obj[0], typeof(ICallable));
    }


    [InlineEmitter("not")]
    public static Expression Not(Expression[] obj)
    {
      return Ast.Condition(Ast.TypeIs(obj[0], typeof(bool)), Ast.Not(Ast.ConvertHelper(obj[0], typeof(bool))), Ast.False());
    }

  }

  public partial class Builtins
  {
    static bool EqualCons(Cons a, Cons b)
    {
      if (ReferenceEquals(a,b))
      {
        return true;
      }
      if (a == null || b == null)
      {
        return false;
      }
      return (bool)IsEquivalent(a.car, b.car) && EqualCons(a.cdr as Cons, b.cdr as Cons);
    }

    [Builtin("equal?")]
    public static object IsEquivalent(object first, object second)
    {
      bool s1 = first is SymbolId;
      bool s2 = second is SymbolId;
      // one exception, symbols
      if (s1 && s2)
      {
        return Equals(first, second);
      }

      if (first == null ^ second == null)
      {
        return FALSE;
      }

      bool c1 = first is Cons;
      bool c2 = second is Cons;

      if (c1 && c2)
      {
        return EqualCons((Cons)first, (Cons)second);
      }

      if (s1 && c2 || s2 && c1)
      {
        return FALSE;
      }

      if ((bool)IsEqualValue(first, second))
      {
        return TRUE;
      }

      Type t1 = first.GetType();
      Type t2 = second.GetType();

      if (t1 == t2)
      {
        return Equals(first, second);
      }

      string w1 = WriteFormat(first);
      string w2 = WriteFormat(second);

      bool result = w1 == w2;

      return GetBool(result);
    }

    [Builtin("eq?")]
    public static object IsEqual(object first, object second)
    {
      // one exception, symbols
      if (first is SymbolId && second is SymbolId)
      {
        return GetBool(Equals(first, second));
      }

      // value types can never have the same reference (theoretically)
      if (first is System.ValueType && second is System.ValueType)
      {
        return FALSE;
      }

      return GetBool(ReferenceEquals(first, second));
    }

    [Builtin("eqv?")]
    public static object IsEqualValue(object first, object second)
    {
      return GetBool(((bool)IsEqual(first, second)) || Equals(first, second));
    }

  }
}
