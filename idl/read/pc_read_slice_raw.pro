; +
; NAME:
;       PC_READ_SLICE_RAW
;
; PURPOSE:
;       Read slices from var.dat, or other VAR files in an efficient way!
;
;       Returns one array from a snapshot (var) file generated by a
;       Pencil Code run, and another array with the variable labels.
;       If you need to be efficient, please use 'pc_collect.x' to combine
;       distributed varfiles before reading them in IDL.
;       This routine can also read reduced datasets from 'pc_reduce.x'.
;
; CATEGORY:
;       Pencil Code, File I/O
;
; CALLING SEQUENCE:
;       pc_read_slice_raw, object=object, varfile=varfile, tags=tags, $
;           datadir=datadir, var_list=var_list, varcontent=varcontent, $
;           param=param, run_param=run_param, /trimall, allprocs=allprocs, $
;           /reduced, cut_x=cut_x, cut_y=cut_y, cut_z=cut_z, $
;           dim=dim, slice_dim=slice_dim, grid=grid, slice_grid=slice_grid, $
;           time=time, /quiet, /swap_endian, /f77
;
; KEYWORD PARAMETERS:
;    datadir: Specifies the root data directory. Default: './data'.  [string]
;    varfile: Name of the snapshot. Default: 'var.dat'.              [string]
;       time: Timestamp of the snapshot.                             [float]
;   allprocs: Load distributed (0) or collective (1 or 2) varfiles.  [integer]
;   /reduced: Load previously reduced collective varfiles (implies allprocs=1).
;        dim: Dimension structure of the global 3D-setup.            [struct]
;  slice_dim: Returns a dimension structure of the loaded 2D-slice.  [struct]
;       grid: Grid structure of the global 3D-setup.                 [struct]
; slice_grid: Returns a grid structure of the loaded 2D-slice.       [struct]
;
;      cut_x: x-coordinate of the yz-plane cut.                      [integer]
;      cut_y: y-coordinate of the xz-plane cut.                      [integer]
;      cut_z: z-coordinate of the xy-plane cut.                      [integer]
;             Exactly one of them must be set in the interval (0,ngrid-1).
;
;     object: Optional object in which to return the loaded data.    [4D-array]
;       tags: Array of tag names inside the object array.            [string(*)]
;   var_list: Array of varcontent idlvars to read (default = all).   [string(*)]
;
;   /trimall: Remove ghost points from the returned data, dim and grid.
;     /quiet: Suppress any information messages and summary statistics.
;
; EXAMPLES:
;
; * Load a slice and display it in a GUI:
;       pc_read_slice_raw, obj=vars, tags=tags, cut_z=4, var_list=["lnrho","uu"], /trimall
;       cslice, vars
;   or:
;       cmp_cslice, { uz:vars[*,*,*,tags.uz], lnrho:vars[*,*,*,tags.lnrho] }
;
; * Load a slice and compute some physical quantity:
;       pc_read_slice_raw, obj=vars, tags=tags, cut_z=4, slice_dim=dim
;       HR_ohm = pc_get_quantity ('HR_ohm', vars, tags, dim=dim)
;       tvscl, HR_ohm
;
; MODIFICATION HISTORY:
;       $Id$
;       Adapted from: pc_read_var_raw.pro, 4th May 2012
;
;-
pro pc_read_slice_raw, object=object, varfile=varfile, tags=tags, datadir=datadir, var_list=var_list, varcontent=varcontent, start_param=start_param, run_param=run_param, trimall=trimall, allprocs=allprocs, reduced=reduced, cut_x=cut_x, cut_y=cut_y, cut_z=cut_z, dim=dim, slice_dim=slice_dim, grid=grid, slice_grid=slice_grid, time=time, quiet=quiet, swap_endian=swap_endian, f77=f77

	; Default settings.
	default, cut_x, -1
	default, cut_y, -1
	default, cut_z, -1

	if (total([cut_x, cut_y, cut_z] < 0) ne -2) then message, 'pc_read_slice_raw: Please set exactly one cut index.'

	if (cut_x ne -1) then begin
		xs = cut_x
		xe = cut_x
	end
	if (cut_y ne -1) then begin
		ys = cut_y
		ye = cut_y
	end
	if (cut_z ne -1) then begin
		zs = cut_z
		ze = cut_z
	end

	pc_read_subvol_raw, object=object, varfile=varfile, tags=tags, datadir=datadir, var_list=var_list, varcontent=varcontent, start_param=start_param, run_param=run_param, trimall=trimall, allprocs=allprocs, reduced=reduced, xs=xs, xe=xe, ys=ys, ye=ye, zs=zs, ze=ze, /addghosts, dim=dim, sub_dim=slice_dim, grid=grid, sub_grid=slice_grid, time=time, name="pc_read_slice_raw", quiet=quiet, swap_endian=swap_endian, f77=f77
end

