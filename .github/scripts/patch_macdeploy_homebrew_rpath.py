from pathlib import Path

path = Path('dist/macdeploy.py')
text = path.read_text()

old = """def FindLibrary(path):
  if os.path.exists(path):
    return path
  for search_path in LIBRARY_SEARCH_PATH:
    abs_path = os.path.join(search_path, path)
    if os.path.exists(abs_path):
      LOGGER.debug(\"Found library '%s' in '%s'\", path, search_path)
      return abs_path

  raise CouldNotFindFrameworkError(path)
"""

new = """def FindLibrary(path):
  if os.path.exists(path):
    return path

  library_names = [path]
  if path.startswith('@rpath/') or path.startswith('@loader_path/'):
    library_names.append(os.path.basename(path))

  search_paths = list(LIBRARY_SEARCH_PATH)
  homebrew_prefix = os.environ.get('HOMEBREW_PREFIX')
  if homebrew_prefix:
    search_paths.extend([
      os.path.join(homebrew_prefix, 'lib'),
      os.path.join(homebrew_prefix, 'opt', 'abseil', 'lib'),
      os.path.join(homebrew_prefix, 'opt', 'protobuf', 'lib'),
    ])

  for search_path in search_paths:
    for library_name in library_names:
      abs_path = os.path.join(search_path, library_name)
      if os.path.exists(abs_path):
        LOGGER.debug(\"Found library '%s' in '%s'\", library_name, search_path)
        return abs_path

  raise CouldNotFindFrameworkError(path)
"""

if old not in text:
  raise SystemExit('FindLibrary block not found in dist/macdeploy.py')

path.write_text(text.replace(old, new))
print('Patched dist/macdeploy.py Homebrew @rpath lookup')
