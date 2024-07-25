/* Include the required headers from httpd */
#include "httpd.h"
#include "http_core.h"
#include "http_protocol.h"

#include "apr_strings.h"

/* Define prototypes of our functions in this module */
static void register_hooks(apr_pool_t *pool);
static int tdc_handler(request_rec *r);

/* Define our module as an entity and assign a function for registering hooks  */

module AP_MODULE_DECLARE_DATA   tdc_module =
{
    STANDARD20_MODULE_STUFF,
    NULL,            // Per-directory configuration handler
    NULL,            // Merge handler for per-directory configurations
    NULL,            // Per-server configuration handler
    NULL,            // Merge handler for per-server configurations
    NULL,            // Any directives we may have for httpd
    register_hooks   // Our hook registering function
};


/* register_hooks: Adds a hook to the httpd process */
static void register_hooks(apr_pool_t *pool) 
{
    
    /* Hook the request handler */
    ap_hook_handler(tdc_handler, NULL, NULL, APR_HOOK_LAST);
}

static int tdc_handler(request_rec *r)
{
    int rc, exists;
    apr_finfo_t finfo;
    apr_file_t* file;
    char *filename, *uri;
    apr_size_t readBytes;
    
    // Check that the "example-handler" handler is being called.
    if (!r->handler || strcmp(r->handler, "tdc-handler")) return (DECLINED);
    
    // Figure out which file is being requested by removing the .sum from it
    filename = apr_pstrdup(r->pool, r->filename);
    uri = apr_pstrdup(r->pool, r->uri);
    
    // Figure out if the file we request a sum on exists and isn't a directory
    rc = apr_stat(&finfo, filename, APR_FINFO_MIN, r->pool);
    if (rc == APR_SUCCESS) {
        exists =
        (
            (finfo.filetype != APR_NOFILE)
        &&  !(finfo.filetype & APR_DIR)
        );
        if (!exists) return HTTP_NOT_FOUND; // Return a 404 if not found.
    }
    // If apr_stat failed, we're probably not allowed to check this file.
    else return HTTP_FORBIDDEN;
    
    rc = apr_file_open(&file, filename, APR_READ, APR_OS_DEFAULT, r->pool);
    if (rc == APR_SUCCESS) {
        char *node = "node ";
        char *tdc_dir = "/usr/lib/tdc/functions.js";
        char *full_command = malloc(strlen(node) + strlen(tdc_dir) + strlen(filename) + strlen(uri) + 3);
        strcpy(full_command, node);
        strcat(full_command, tdc_dir);
        strcat(full_command, " ");
        strcat(full_command, filename);
        strcat(full_command, " ");
        strcat(full_command, uri);
        FILE* file2 = popen (full_command, "r");
        char buffer2[10];
        if (fscanf(file2, "%s", buffer2) == 1) {
            if(!strcmp(buffer2, "false")){
                return HTTP_FORBIDDEN;
            }
            pclose (file2);
        }
        ap_send_fd(file, r, 0, r->finfo.size, &readBytes);
        apr_file_close(file);
    }
    
    
    
    // Let Apache know that we responded to this request.
    return OK;
}