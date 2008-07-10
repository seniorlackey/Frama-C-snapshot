(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) 2001-2003,                                              *)
(*   George C. Necula    <necula@cs.berkeley.edu>                         *)
(*   Scott McPeak        <smcpeak@cs.berkeley.edu>                        *)
(*   Wes Weimer          <weimer@cs.berkeley.edu>                         *)
(*   Ben Liblit          <liblit@cs.berkeley.edu>                         *)
(*  All rights reserved.                                                  *)
(*                                                                        *)
(*  Redistribution and use in source and binary forms, with or without    *)
(*  modification, are permitted provided that the following conditions    *)
(*  are met:                                                              *)
(*                                                                        *)
(*  1. Redistributions of source code must retain the above copyright     *)
(*  notice, this list of conditions and the following disclaimer.         *)
(*                                                                        *)
(*  2. Redistributions in binary form must reproduce the above copyright  *)
(*  notice, this list of conditions and the following disclaimer in the   *)
(*  documentation and/or other materials provided with the distribution.  *)
(*                                                                        *)
(*  3. The names of the contributors may not be used to endorse or        *)
(*  promote products derived from this software without specific prior    *)
(*  written permission.                                                   *)
(*                                                                        *)
(*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS   *)
(*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT     *)
(*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     *)
(*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE        *)
(*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,   *)
(*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,  *)
(*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;      *)
(*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER      *)
(*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT    *)
(*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN     *)
(*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *)
(*  POSSIBILITY OF SUCH DAMAGE.                                           *)
(*                                                                        *)
(*  File modified by CEA (Commissariat � l'�nergie Atomique).             *)
(**************************************************************************)

open Cil
open Cil_types
open Cilutil

type t =
    { sloc: int;
      call_statements: int;
      goto_statements: int;
      assign_statements: int;
      if_statements: int;
      loop_statements: int;
      mem_access: int;
      functions_without_source: int VarinfoHashtbl.t;
      functions_with_source: int VarinfoHashtbl.t;
    }

let pretty_set fmt s =
  Format.fprintf fmt "@[";
  VarinfoHashtbl.iter 
    (fun f n ->
       Format.fprintf fmt "%s %s (%d call%s);@ " 
	 f.vname
         (if f.vaddrof then "(address taken)" else "")
	 n (if n > 1 then "s" else ""))
    s;
  Format.fprintf fmt "@]"

let number_entry_points fs =
  VarinfoHashtbl.fold 
    (fun f n acc -> if n = 0 && not f.vaddrof then succ acc else acc)
    fs
    0

let pretty_entry_points fmt fs =
  let print =   
    VarinfoHashtbl.iter 
      (fun f n -> 
	 if n = 0 && not f.vaddrof then Format.fprintf fmt "%s;@ " f.vname)
  in
  Format.fprintf fmt "@[";
  print fs;
  Format.fprintf fmt "@]"

let pretty fmt { if_statements = ifs;
                 mem_access = mem_access;
                 loop_statements = loops;
                 call_statements = calls;
                 assign_statements = assigns;
                 goto_statements = gotos;
                 sloc =  sloc;
                 functions_without_source =  fws;
                 functions_with_source = fs; } =

  Format.fprintf fmt
    "@[Defined function (%d):@\n  @[%a@]@\nUndefined functions (%d):@\n  @[%a@]@\nPotential entry points (%d):@\n  @[%a@]@\nSLOC: %d@\nNumber of if statements %d@\nNumber of assignments %d@\nNumber of loops %d@\nNumber of calls %d@\nNumber of gotos %d@\nNumber of pointer access %d@]"
    (VarinfoHashtbl.length fs)
    pretty_set fs
    (VarinfoHashtbl.length fws)
    pretty_set fws
    (number_entry_points fs)
    pretty_entry_points fs
    sloc
    ifs
    assigns
    loops
    calls
    gotos
    mem_access

let dump filename data =
  try
    let cout = open_out_bin filename in
    let fmt = Format.formatter_of_out_channel cout in
    pretty fmt data;
    close_out cout
  with Sys_error _ as e ->
    Cil.warn "Cannot open file %s for dumpimp metrics: %s" 
      filename (Printexc.to_string e)

class slocVisitor = object
  inherit nopCilVisitor
  val mutable sloc = 0
  val mutable ifs = 0
  val mutable loops = 0
  val mutable calls = 0
  val mutable gotos = 0
  val mutable assigns = 0
  method assigns = assigns
  method calls = calls
  method gotos = gotos
  method loops = loops
  method ifs = ifs
  val mutable mem_access = 0
  method mem_access = mem_access
  val functions_no_source = VarinfoHashtbl.create 97
  val functions_with_source = VarinfoHashtbl.create 97
  method functions_no_source = functions_no_source
  method functions_with_source = functions_with_source
  method vvdec vi =
    if isFunctionType vi.vtype then
      if not (VarinfoHashtbl.mem functions_with_source vi) then
	VarinfoHashtbl.replace functions_no_source vi
	  (try VarinfoHashtbl.find functions_no_source vi
	   with Not_found -> 0);
    DoChildren

  method vfunc fdec =
    let n =
      try 
	let n = VarinfoHashtbl.find functions_no_source fdec.svar in
	VarinfoHashtbl.remove functions_no_source fdec.svar;
	n
      with Not_found ->	
	0
    in
    let n =
      try VarinfoHashtbl.find functions_with_source fdec.svar + n
      with Not_found -> n
    in
    VarinfoHashtbl.replace functions_with_source fdec.svar n;
    DoChildren

  method vlval (host,_) =
    begin
      match host with
      | Mem _ -> mem_access <- mem_access + 1
      | _ -> ()
    end;
    DoChildren

  method sloc = sloc
  method vstmt s =
    sloc <- sloc + 1 ;
    begin match s.skind with
    | If _ -> ifs <- ifs + 1
    | Loop _ -> loops <- loops + 1
    | Goto _ -> gotos <- gotos + 1
    | _ -> ()
    end;
    DoChildren

  method vinst i =
    begin match i with
    | Call(_, e, _, _) -> 
	calls <- calls + 1;
	(match e with
	 | Lval(Var v, NoOffset) ->
	     let next tbl =
	       VarinfoHashtbl.replace tbl v (succ (VarinfoHashtbl.find tbl v))
	     in begin
	       try next functions_with_source 		
	       with Not_found -> 
		 try next functions_no_source with Not_found -> assert false
	     end
	 | _ -> ())
    | Set _ -> assigns <- assigns + 1
    | _ -> ()
    end;
    DoChildren

end

(* This may be used to generate code associated to prototypes.

let find_lvals_to_assign vi =
  let rec rec_find_lvals lval =
    let typ = typeOfLval lval in
    if isArithmeticType typ then [lval]
    else if isPointerType typ then
      rec_find_lvals (mkMem ~addr:(Lval lval) ~off:NoOffset)
    else assert false
  in
  if isPointerType vi.vtype then
    (* find the lvals of basic types *)
    rec_find_lvals (mkMem ~addr:(Lval (Var vi,NoOffset)) ~off:NoOffset)
  else []

let make_body_from_prototype vi =
  vi.vstorage <- NoStorage;
  let new_fundec =
    { svar  = vi;
      smaxid = 0;
      slocals = [];
      sformals = [];
      sbody = mkBlock [];
      smaxstmtid = None;
      sallstmts = [];
      sspec =   {requires = None;
                 assigns = None;
                 ensures = None;
                 decreases = None}
    }
  in
  (* formal might have no name, let's fix the type to generate a name:*)
  vi.vtype <- begin match vi.vtype with
  | TFun (typ, None, b, attr) ->  vi.vtype
  | TFun (typ, Some args, b, attr) ->
      let counter = ref 0 in
      let named_args =
        List.map
          (fun (n,t,a) ->
             (if n= "" then
                begin incr counter;
                  "Frama_C_formals_"^(string_of_int !counter)
                end
              else n),
             t,a)
          args
      in
      TFun (typ, Some named_args, b, attr)
  | _ -> assert false
  end;
  setFunctionTypeMakeFormals new_fundec vi.vtype;
  let fresh_global = GFun (new_fundec,vi.vdecl) in
  let fresh_volatile =
    makeLocalVar
      new_fundec
      "Frama_C_entropy_source"
    (typeAddAttributes [Attr ("volatile",[])] (TInt(IULongLong, [])) )
  in
  let volatile_lval = Lval(Var fresh_volatile,NoOffset) in
  List.iter (fun formal ->
               let lvals_to_assign = find_lvals_to_assign formal in
               let stmts =
                 List.map
                   (fun lval_to_assign ->
                      mkStmtOneInstr
                        (Set (lval_to_assign,
                              volatile_lval,
                              vi.vdecl)))
                   lvals_to_assign
               in
               let conditional
               new_fundec.sbody.bstmts <- new_fundec.sbody.bstmts@stmts;
            )
    new_fundec.sformals;

  Format.printf "Made: <@\n %a@\n>@." d_global fresh_global;
  new_fundec

class turn_prototype_into_body protos_vi turn_into = object(self)
  inherit nopCilVisitor

  method vglob glob =
    match glob with
    | GVarDecl (fspec, vi, loc) when VarinfoSet.mem vi protos_vi ->
        assert (isFunctionType vi.vtype);
        ChangeTo [GFun(make_body_from_prototype vi,loc)]

    | _ -> SkipChildren

end

*)

let sloc file =
  let v = new slocVisitor in
  visitCilFileSameGlobals (v:>cilVisitor) file;
(*  let changer =
    new turn_prototype_into_body
      v#functions_no_source
      make_body_from_prototype
  in
  visitCilFile (changer:>cilVisitor) file;*)
  { call_statements = v#calls;
    goto_statements = v#gotos;
    assign_statements = v#assigns;
    if_statements = v#ifs;
    mem_access = v#mem_access;
    loop_statements = v#loops;
    sloc = v#sloc;
    functions_without_source =  v#functions_no_source;
    functions_with_source =  v#functions_with_source;
  }