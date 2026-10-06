import path from 'node:path';

// Folder name of this package inside node_modules. It equals the dependency key in the
// app's package.json, so it is also correct when installed through an npm alias.
export const PACKAGE_DIR_NAME = path.basename(path.resolve(__dirname, '..', '..'));
