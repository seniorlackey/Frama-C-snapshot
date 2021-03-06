(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2017                                               *)
(*    CEA (Commissariat à l'énergie atomique et aux énergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

include Plugin.Register
  (struct
     let name = "report"
     let shortname = "report"
     let help = "Properties Status Report (experimental)"
   end)

module Enabled =
  False
    (struct
      let option_name = "-report"
      let help = "display a summary of properties status"
     end)

module PrintProperties =
  False
    (struct
      let option_name = "-report-print-properties"
      let help = "print not only the locations, but also the \
                             properties themselves"
     end)

module Untried =
  False
    (struct
      let option_name = "-report-untried"
      let help = "display properties which no plug-in tried to prove"
     end)

module Specialized =
  True
    (struct
      let option_name = "-report-specialized"
      let help = "display properties that are auxiliary instances of other \
          properties."
     end)

module Proven =
  True
    (struct
      let option_name = "-report-proven"
      let help = "if set, output proven properties. Otherwise, only unproven \
                   ones are shown."
     end)


module CSVFile =
  String
    (struct
      let option_name = "-report-csv"
      let arg_name = "name"
      let default = ""
      let help = "if set, output properties as a csv file of the given name"
     end)
