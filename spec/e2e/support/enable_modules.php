<?php

// Enable the Dolibarr modules the e2e billing cycle needs, using Dolibarr's own
// activateModule() so rights (llx_rights_def), dictionaries and consts are populated
// exactly as a UI enable would. A raw SQL `MAIN_MODULE_*` const insert is NOT enough:
// it leaves llx_rights_def empty, so even the superadmin gets HTTP 403 on the API.
//
// Run inside the dolibarr container as www-data, e.g.:
//   docker compose exec -u www-data -T dolibarr php < enable_modules.php

$_SERVER['DOCUMENT_ROOT'] = '/var/www/html';
require '/var/www/html/master.inc.php';
require_once DOL_DOCUMENT_ROOT . '/core/lib/admin.lib.php';

$modules = ['modApi', 'modSociete', 'modFacture', 'modBanque', 'modService', 'modProduct'];
$failed = [];
foreach ($modules as $module) {
    $res = activateModule($module);
    if (!empty($res['errors'])) {
        $failed[$module] = $res['errors'];
    }
}

if ($failed) {
    fwrite(STDERR, 'module activation failed: ' . json_encode($failed) . "\n");
    exit(1);
}

echo 'modules enabled: ' . implode(', ', $modules) . "\n";
