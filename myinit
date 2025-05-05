#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/resource.h>

#define MAX_PROCESSES 100
#define MAX_LINE_LENGTH 1024

struct ProcessConfig {
    char **arguments;
    char* input_file;
    char* output_file;
};

int active_processes_count;
pid_t process_pids[MAX_PROCESSES];
struct ProcessConfig process_configs[MAX_PROCESSES];
char log_buffer[MAX_LINE_LENGTH];
char config_file_path[MAX_LINE_LENGTH];
FILE* log_stream;

void write_to_log(char *message) {
    fwrite(message, 1, strlen(message), log_stream);
    fflush(log_stream);
}

struct ProcessConfig parse_process_config(char* config_line) {
    char* token = strtok(config_line, " ");
    struct ProcessConfig config;

    config.arguments = malloc(strlen(token) + 1);
    int arg_index = 0;

    while (token) {
        config.arguments[arg_index] = malloc(strlen(token));
        strcpy(config.arguments[arg_index++], token);
        token = strtok(NULL, " ");
    }

    config.input_file = config.arguments[arg_index - 2];
    config.output_file = config.arguments[arg_index - 1];
    config.arguments[arg_index - 2] = NULL;
    config.arguments[arg_index - 1] = NULL;

    return config;
}

void launch_process(int process_index) {
    struct ProcessConfig config = process_configs[process_index];
    pid_t child_pid = fork();

    if (child_pid) {
        process_pids[process_index] = child_pid;
        active_processes_count++;
        snprintf(log_buffer, sizeof(log_buffer),
                "Task %d started %s with pid: %d\n",
                process_index, config.arguments[0], child_pid);
        write_to_log(log_buffer);
    } else {
        freopen(config.input_file, "r", stdin);
        freopen(config.output_file, "w", stdout);
        execv(config.arguments[0], config.arguments);
    }
}

void initialize_processes() {
    FILE* config_file = fopen(config_file_path, "r");
    char* line = NULL;
    size_t line_length = 0;
    int config_count = 0;

    while (getline(&line, &line_length, config_file) != -1) {
        process_configs[config_count++] = parse_process_config(line);
    }

    for (int i = 0; i < config_count; i++) {
        launch_process(i);
    }

    while (active_processes_count) {
        int status = 0;
        pid_t child_pid = waitpid(-1, &status, 0);

        for (int i = 0; i < config_count; i++) {
            if (process_pids[i] == child_pid) {
                snprintf(log_buffer, sizeof(log_buffer),
                        "Task %d finished with status: %d\n", i, status);
                write_to_log(log_buffer);
                process_pids[active_processes_count--] = 0;
                launch_process(i);
            }
        }
    }
}

void handle_sighup(int signal) {
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (process_pids[i]) {
            kill(process_pids[i], SIGKILL);
            snprintf(log_buffer, sizeof(log_buffer),
                    "Task %d killed\n", i);
            write_to_log(log_buffer);
        }
    }
    write_to_log("Restarting myinit\n");
    initialize_processes();
}

void close_file_descriptors() {
    struct rlimit fd_limit;
    getrlimit(RLIMIT_NOFILE, &fd_limit);
    for (int fd = 0; fd < fd_limit.rlim_max; fd++)
        close(fd);
}

void setup_environment(char *argv[]) {
    chdir("/");
    close_file_descriptors();

    if (getppid() != 1) {
        signal(SIGTTOU, SIG_IGN);
        signal(SIGTTIN, SIG_IGN);
        if (fork() != 0) exit(0);
        setsid();
    }

    log_stream = fopen("/tmp/myinit.log", "w");
    write_to_log("Starting myinit\n");
    strcpy(config_file_path, argv[1]);
    signal(SIGHUP, handle_sighup);
}

int main(int argc, char *argv[]) {
    setup_environment(argv);
    initialize_processes();
    return 0;
}
