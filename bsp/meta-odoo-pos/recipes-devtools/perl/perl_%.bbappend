do_install_ptest() {
    cat << 'EOF' > ${WORKDIR}/install-ptest.py
import sys
import shutil
import os
import re
import fnmatch

D = sys.argv[1]
PTEST_PATH = sys.argv[2]
S = sys.argv[3]
bindir = sys.argv[4]
debug_prefix_map_regex = sys.argv[5]
staging_dir_host = sys.argv[6]
staging_incdir = sys.argv[7]
staging_libdir = sys.argv[8]
staging_bindir = sys.argv[9]
staging_bindir_native = sys.argv[10]
staging_bindir_toolchain = sys.argv[11]
target_prefix = sys.argv[12]
recipe_sysroot_native = sys.argv[13]
recipe_sysroot = sys.argv[14]
libdir = sys.argv[15]
includedir = sys.argv[16]

d_ptest_path = os.path.join(D, PTEST_PATH.lstrip('/'))
os.makedirs(d_ptest_path, exist_ok=True)

# 1. sed replacements in sources (before copying)
def sed_replace(file_path, pattern, replacement):
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', errors='ignore') as f:
                content = f.read()
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                with open(file_path, 'w', errors='ignore') as f:
                    f.write(new_content)
        except Exception as e:
            print("Warning: Failed to sed %s: %s" % (file_path, str(e)))

cpan_t_dir = os.path.join(S, 'cpan/version/t')
if os.path.exists(cpan_t_dir):
    for f in os.listdir(cpan_t_dir):
        sed_replace(os.path.join(cpan_t_dir, f), r'/usr/local', bindir)

sed_replace(os.path.join(S, 'Porting/add-package.pl'), r'/opt', r'/usr')
sed_replace(os.path.join(S, 'hints/cxux.sh'), r'/local/gnu/', r'/')

# 2. Copy files with exclusion logic matching the original tar command
excludes = [
    'try', 'a.out', '*.o', 'libperl.so*', '*Makefile', '*makefile', 'hostperl',
    'cygwin', 'os2', 'djgpp', 'qnx', 'symbian', 'haiku',
    'vms', 'vos', 'NetWare', 'amigaos4', 'buildcustomize.pl',
    'plan9', 'README.plan9', 'perlplan9.pod', 'Configure',
    'veryclean.sh', 'realclean.sh', 'getioctlsizes',
    'dl_aix.xs', 'sdbm.3', 'cflags.SH', '*Makefile.old', '*makefile.old',
    'miniperl', 'generate_uudmap', 'patches', 'config.log'
]

def is_excluded(path, name):
    rel_path = os.path.join(path, name)
    for pattern in excludes:
        if fnmatch.fnmatch(name, pattern) or fnmatch.fnmatch(rel_path, pattern):
            return True
    if rel_path.startswith('win32/') and fnmatch.fnmatch(name, 'config.*'):
        return True
    return False

for root, dirs, files in os.walk(S):
    rel_root = os.path.relpath(root, S)
    
    filtered_dirs = []
    for d_name in dirs:
        if not is_excluded('' if rel_root == '.' else rel_root, d_name):
            filtered_dirs.append(d_name)
    dirs[:] = filtered_dirs

    dest_dir = d_ptest_path if rel_root == '.' else os.path.join(d_ptest_path, rel_root)
    
    for d_name in dirs:
        src_subdir = os.path.join(root, d_name)
        dest_subdir = os.path.join(dest_dir, d_name)
        if os.path.islink(src_subdir):
            link_to = os.readlink(src_subdir)
            if os.path.exists(dest_subdir) or os.path.islink(dest_subdir):
                os.unlink(dest_subdir)
            os.symlink(link_to, dest_subdir)
        else:
            os.makedirs(dest_subdir, exist_ok=True)
            stat = os.stat(src_subdir)
            os.chmod(dest_subdir, stat.st_mode)

    for f_name in files:
        if not is_excluded('' if rel_root == '.' else rel_root, f_name):
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

# 3. Post-copy link
t_perl = os.path.join(d_ptest_path, 't/perl')
if os.path.exists(t_perl) or os.path.islink(t_perl):
    os.unlink(t_perl)
os.symlink(os.path.join(bindir, 'perl'), t_perl)

# 4. Remove build host references from installed files
file_patterns = ['*.PL', 'myconfig', 'cflags', '*.pl', '*.sh', '*.pm', 'h2xs', 'h2ph', '*.h', 'config.sh-*', 'pod2man', 'pod2text', 'Makefile.config']

for root, dirs, files in os.walk(d_ptest_path):
    for f_name in files:
        matches = False
        for pat in file_patterns:
            if fnmatch.fnmatch(f_name, pat):
                matches = True
                break
        if matches:
            f_path = os.path.join(root, f_name)
            if not os.path.islink(f_path):
                try:
                    with open(f_path, 'r', errors='ignore') as f:
                        content = f.read()
                    
                    new_content = content
                    new_content = new_content.replace(D, '')
                    if staging_dir_host:
                        new_content = new_content.replace('--sysroot=' + staging_dir_host, '')
                    if staging_incdir:
                        new_content = new_content.replace('-isystem' + staging_incdir + ' ', '')
                    
                    if debug_prefix_map_regex:
                        new_content = re.sub(debug_prefix_map_regex, '', new_content)
                        
                    if staging_bindir_native:
                        new_content = new_content.replace(staging_bindir_native + '/perl-native/', bindir + '/')
                    if staging_libdir:
                        new_content = new_content.replace(staging_libdir, libdir)
                    if staging_bindir:
                        new_content = new_content.replace(staging_bindir, bindir)
                    if staging_incdir:
                        new_content = new_content.replace(staging_incdir, includedir)
                    if staging_bindir_native:
                        new_content = new_content.replace(staging_bindir_native + '/', '')
                    if staging_bindir_toolchain and target_prefix:
                        new_content = new_content.replace(staging_bindir_toolchain + '/' + target_prefix, bindir)
                    if recipe_sysroot_native:
                        new_content = new_content.replace(recipe_sysroot_native, '')
                    if recipe_sysroot:
                        new_content = new_content.replace(recipe_sysroot, '')
                    
                    if new_content != content:
                        with open(f_path, 'w', errors='ignore') as f:
                            f.write(new_content)
                except Exception as e:
                    print("Warning: Failed to strip host paths from %s: %s" % (f_path, str(e)))

# 5. Remove useless timestamp
mktables_path = os.path.join(d_ptest_path, 'lib/unicore/mktables.lst')
if os.path.exists(mktables_path):
    try:
        with open(mktables_path, 'r', errors='ignore') as f:
            lines = f.readlines()
        new_lines = [line for line in lines if 'Autogenerated starting on' not in line]
        with open(mktables_path, 'w', errors='ignore') as f:
            f.writelines(new_lines)
    except Exception as e:
        print("Warning: Failed to update %s: %s" % (mktables_path, str(e)))

# 6. Remove native host-specific configuration files
for filename in ['Makefile.config', 'xconfig.h', 'xconfig.sh']:
    f_path = os.path.join(d_ptest_path, filename)
    if os.path.exists(f_path):
        os.remove(f_path)

# 7. Create empty win32/Makefile
touch_path = os.path.join(d_ptest_path, 'win32/Makefile')
os.makedirs(os.path.dirname(touch_path), exist_ok=True)
with open(touch_path, 'a'):
    os.utime(touch_path, None)
EOF
    python3 ${WORKDIR}/install-ptest.py \
        "${D}" \
        "${PTEST_PATH}" \
        "${S}" \
        "${bindir}" \
        "${DEBUG_PREFIX_MAP_REGEX}" \
        "${STAGING_DIR_HOST}" \
        "${STAGING_INCDIR}" \
        "${STAGING_LIBDIR}" \
        "${STAGING_BINDIR}" \
        "${STAGING_BINDIR_NATIVE}" \
        "${STAGING_BINDIR_TOOLCHAIN}" \
        "${TARGET_PREFIX}" \
        "${RECIPE_SYSROOT_NATIVE}" \
        "${RECIPE_SYSROOT}" \
        "${libdir}" \
        "${includedir}"
}
