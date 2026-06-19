python do_prep_locale_tree() {
    import shutil
    import os
    import gzip
    import fnmatch

    treedir = os.path.join(d.getVar('WORKDIR'), 'locale-tree')
    if os.path.exists(treedir):
        shutil.rmtree(treedir)

    os.makedirs(os.path.join(treedir + d.getVar('base_bindir')), exist_ok=True)
    os.makedirs(os.path.join(treedir + d.getVar('base_libdir')), exist_ok=True)
    os.makedirs(os.path.join(treedir + d.getVar('datadir')), exist_ok=True)
    os.makedirs(os.path.join(treedir + d.getVar('localedir')), exist_ok=True)

    src_i18n = os.path.join(d.getVar('LOCALETREESRC') + d.getVar('datadir'), 'i18n')
    dst_i18n = os.path.join(treedir + d.getVar('datadir'), 'i18n')

    if os.path.exists(src_i18n):
        if os.path.exists(dst_i18n):
            shutil.rmtree(dst_i18n)
        shutil.copytree(src_i18n, dst_i18n, symlinks=True)

    # unzip charmaps
    charmaps_dir = os.path.join(dst_i18n, 'charmaps')
    if os.path.exists(charmaps_dir):
        for f in os.listdir(charmaps_dir):
            if f.endswith('.gz'):
                gz_path = os.path.join(charmaps_dir, f)
                unzipped_path = os.path.join(charmaps_dir, f[:-3])
                with gzip.open(gz_path, 'rb') as f_in:
                    with open(unzipped_path, 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                os.remove(gz_path)

    # copy files matching l*.so* from base_libdir
    src_baselib = d.getVar('LOCALETREESRC') + d.getVar('base_libdir')
    dst_baselib = treedir + d.getVar('base_libdir')
    if os.path.exists(src_baselib):
        for root, dirs, files in os.walk(src_baselib):
            rel_root = os.path.relpath(root, src_baselib)
            dest_dir = dst_baselib if rel_root == '.' else os.path.join(dst_baselib, rel_root)
            
            for d_name in dirs:
                src_dir = os.path.join(root, d_name)
                dest_subdir = os.path.join(dest_dir, d_name)
                if os.path.islink(src_dir):
                    link_to = os.readlink(src_dir)
                    if os.path.exists(dest_subdir) or os.path.islink(dest_subdir):
                        os.unlink(dest_subdir)
                    os.symlink(link_to, dest_subdir)
                else:
                    os.makedirs(dest_subdir, exist_ok=True)
                    stat = os.stat(src_dir)
                    os.chmod(dest_subdir, stat.st_mode)

            for f_name in files:
                if fnmatch.fnmatch(f_name, 'l*.so*'):
                    src_file = os.path.join(root, f_name)
                    dest_file = os.path.join(dest_dir, f_name)
                    os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                    if os.path.islink(src_file):
                        link_to = os.readlink(src_file)
                        if os.path.exists(dest_file) or os.path.islink(dest_file):
                            os.unlink(dest_file)
                        os.symlink(link_to, dest_file)
                    else:
                        shutil.copy2(src_file, dest_file)

    # copy libgcc_s.*
    staging_libdir_native = d.getVar('STAGING_LIBDIR_NATIVE')
    if os.path.exists(staging_libdir_native):
        for f_name in os.listdir(staging_libdir_native):
            if fnmatch.fnmatch(f_name, 'libgcc_s.*'):
                src_file = os.path.join(staging_libdir_native, f_name)
                dest_file = os.path.join(dst_baselib, f_name)
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                if os.path.islink(src_file):
                    link_to = os.readlink(src_file)
                    if os.path.exists(dest_file) or os.path.islink(dest_file):
                        os.unlink(dest_file)
                    os.symlink(link_to, dest_file)
                else:
                    shutil.copy2(src_file, dest_file)

    # install localedef executable
    src_localedef = d.getVar('LOCALETREESRC') + d.getVar('bindir') + '/localedef'
    dst_localedef = os.path.join(treedir + d.getVar('base_bindir'), 'localedef')
    if os.path.exists(src_localedef):
        os.makedirs(os.path.dirname(dst_localedef), exist_ok=True)
        shutil.copy2(src_localedef, dst_localedef)
        os.chmod(dst_localedef, 0o755)
}

python do_collect_bins_from_locale_tree() {
    import shutil
    import os
    import subprocess

    treedir = os.path.join(d.getVar('WORKDIR'), 'locale-tree')
    localedir = d.getVar('localedir')
    pkgd = d.getVar('PKGD')

    parent = os.path.dirname(localedir)
    base_locale = os.path.basename(localedir)

    src = os.path.join(treedir + parent, base_locale)
    dest = os.path.join(pkgd + parent, base_locale)

    if os.path.exists(src):
        if os.path.exists(dest):
            shutil.rmtree(dest)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copytree(src, dest, symlinks=True)

    # Finalize tree by changing all duplicate files into hard links
    cmd = ["cross-localedef-hardlink", "-c", "-v", os.path.join(d.getVar('WORKDIR'), 'locale-tree')]
    subprocess.run(cmd, check=True)
}
