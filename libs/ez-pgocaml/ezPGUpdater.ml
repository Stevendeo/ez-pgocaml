
let main database ?(downgrades=[]) ?host ?port ?user ?password ~upgrades =
  Printf.eprintf "EzPGUpdater.main on %s@." database;
  let database = ref database in
  let verbose = ref false in
  let witness = ref None in
  let max_version = List.length upgrades in
  let target = ref max_version in
  let old_info = ref false in
  let allow_downgrade = ref false in
  let use_current = ref false in
  Arg.parse [
      "--verbose", Arg.Set verbose, " Set verbose mode";
      "--witness", Arg.String (fun s -> witness := Some s),
      "FILE Touch FILE if database is modified";
      "--dropdb", Arg.Unit (fun () ->
                      EzPG.dropdb !database;
                      exit 0
                    ), " Drop database";
      "--createdb", Arg.Unit (fun () ->
                      EzPG.createdb !database;
                      exit 0
                      ), " Create database";
      "--target", Arg.Int (fun n ->
                      if n > max_version then begin
                          Printf.eprintf "Cannot target version > %d\n%!"
                                         max_version;
                          exit 2
                        end;
                      target := n),
      "VERSION Target version VERSION";
      "--old-info", Arg.Set old_info, " Use old 'info' table name";
      "--allow-downgrade", Arg.Set allow_downgrade, " Allow downgrade";
      "--use-current", Arg.Set use_current, " Use current downgrades instead of DB";
    ] (fun s -> database := s)
            (Printf.sprintf
               "database-updater [OPTIONS] [database] (default %S)"
            !database);
  let database = !database in
  let verbose = !verbose in
  let witness = !witness in
  let target = !target in

  let dbh =
    try
      let dbh = EzPG.connect ?host ?port ?user ?password database in
      Printf.eprintf "Connection to database %s OK@." database;
      dbh
    with _ ->
      Printf.eprintf "Database not found, creating database %s@." database;
      EzPG.createdb ?host ?port ?user ?password database;
      Printf.eprintf "Database %s created, connecting..." database;
      let dbh = EzPG.connect ?host ?port ?user ?password database in
      EzPG.init ?witness dbh;
      dbh
  in
  let downgrades = if !use_current then Some downgrades else None in
  Printf.eprintf "Use current %b %b\n%!" !use_current (downgrades = None);
  if !old_info then EzPG.may_upgrade_old_info ~verbose dbh;
  EzPG.upgrade_database
    ~allow_downgrade: !allow_downgrade
    ~target ~verbose ?witness dbh ~upgrades ?downgrades;
  EzPG.close dbh
