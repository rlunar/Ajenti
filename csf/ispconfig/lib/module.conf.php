<?php

//**** Module Definition ****

// Name of the module. The module name must match the name of the module directory.
// The module name may not contain spaces.
$module['name']      = 'csf';

// Title of the module which is dispalayed in the top navigation.
$module['title']     = 'Security';

// The template file of the module. This is always 'module.tpl.htm' unless
// there are any special requirements such as a three column layout.
$module['template']  = 'module.tpl.htm';

// The page that is displayed when the module is loaded.
// The path must is relative to the web/ directory
$module['startpage'] = 'csf/ispconfig_csf_r.php';

// The width of the tab. Normally you should leave this empty and
// let the browser define the width automatically.
$module['tab_width'] = '';

//****  Menu Definition ****

// Make sure that the items array is empty
$items = array();

$items[] = array( 'title'   => 'ConfigServer Firewall',
                  'target'  => 'content',
                  'link'    => 'csf/ispconfig_csf_r.php'
                );

$module['nav'][] = array( 'title' => 'ConfigServer',
                          'open'  => 1,
                          'items'	=> $items
                        );
?>

