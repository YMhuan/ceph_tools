/*
 > Author: YM
 > Description:
 > version:
 > Support:
 > Others:
 > Changelogs:
 */

#include <ctype.h>
#include <errno.h>
#include <math.h>
#include <pthread.h>
#include <regex.h>
#include <signal.h>
#include <stdarg.h> /* ANSI C header file */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h> /* for syslog() */
#include <time.h>
#include <unistd.h>
#include <uuid/uuid.h>
#include <sys/stat.h>
#include <sys/types.h>

#define Objects_Path "objs"
#define FileName_Prefix "s3test"

struct TaskInfo {
    pthread_t tid;
    int index;
    int size;
    int num;
};

pthread_mutex_t mutex;

int exec_command_v2(const char *fmt, ...)
{
    if (fmt == NULL)
    {
        printf("Invalid command!\n");
        return -1;
    }

    char cmd[1024] = {'\0'};
    va_list ap;
    va_start(ap, fmt);
    vsprintf(cmd, fmt, ap);
    va_end(ap);

    return system(cmd);
}

int exec_command(const char *fmt, ...)
{
    if (fmt == NULL)
    {
        printf("Invalid command!\n");
        return -1;
    }

    char cmd[1024] = {'\0'};
    va_list ap;
    va_start(ap, fmt);
    vsprintf(cmd, fmt, ap);
    va_end(ap);

    FILE *fstream = popen(cmd, "r");
    if (fstream == NULL)
    {
        printf("fstream is NULL!\n");
        return -1;
    }

    pclose(fstream);
    return 0;
}

int generate_objfile(const char *filename, int size)
{
    if(!filename) {
        printf("Invalid filename\n");
        return -1;
    }

    FILE *fp = fopen(filename, "wb");
    if(!fp) {
        printf("Failed to open %s\n", filename);
        return -1;
    }

    if (size > 0) {
        if (size > 1048576)
            size = 1048576;
        char *buf = (char *) malloc(size);
        if (buf) {
            fwrite(buf, size, 1, fp);
            free(buf);
            buf = NULL;
        }
    }

    fclose(fp);
    return 0;
}

void *put_objects_to_s3(void *data)
{
    struct TaskInfo *taskinfo = (struct TaskInfo *)data;
    if (!taskinfo) {
        printf("Invilid data!\n");
        pthread_exit(0);
    }

    printf("worker-%d is starting...\n", taskinfo->index);

    char objfile[1024] = {'\0'};
    sprintf(objfile, "%s/%s-worker%d.dat", Objects_Path, FileName_Prefix, taskinfo->index);
    generate_objfile(objfile, taskinfo->size);

    uuid_t uuid;
    char struuid[64] = {'\0'};

    int i = 0;
    for (i = 0; i < taskinfo->num; i ++)
    {
        uuid_generate(uuid);
        uuid_unparse(uuid, struuid);
        // printf("s3cmd put %s s3://bucket01/%s-worker%d-%s.dat\n", objfile, FileName_Prefix, taskinfo->index, struuid);
        int ret = exec_command_v2("s3cmd put %s s3://bucket01/%s-worker%d-%s.dat\n", objfile, FileName_Prefix, taskinfo->index, struuid);
        if (ret < 0)
        {
            printf("Failed to put %s ==> s3://bucket01/%s-worker%d-%s.dat\n", objfile, FileName_Prefix, taskinfo->index, struuid);
        }
    }

    printf("worker-%d is exiting...\n", taskinfo->index);

    unlink(objfile);
    pthread_exit(0);
}

int main(int argc, const char *argv[])
{
    int num_of_thread = 8;
    int nums = 1000;
    if (argc > 2)
    {
        num_of_thread = atoi(argv[1]);
        nums = atoi(argv[2]);
    }

    printf("%d workers will be created:\n", num_of_thread);
    mkdir(Objects_Path, 0755);

    struct TaskInfo *taskinfo = (struct TaskInfo *)malloc(sizeof(struct TaskInfo) * num_of_thread);
    if (taskinfo)
    {
        int i = 0;
        for (i = 0; i < num_of_thread; i ++)
        {
            struct TaskInfo *ptask = &taskinfo[i];
            ptask->index = i;
            ptask->size = 1024;
            ptask->num = nums;
            pthread_create(&ptask->tid, NULL, put_objects_to_s3, ptask);
        }

        for (i = 0; i < num_of_thread; i ++)
        {
            struct TaskInfo *ptask = &taskinfo[i];
            pthread_join(ptask->tid, NULL);
        }
    }

    rmdir(Objects_Path);

    free(taskinfo);
    taskinfo = NULL;

    return 0;
}
