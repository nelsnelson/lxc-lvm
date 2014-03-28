
#include <time.h>
#include <unistd.h>

int main()
{
    if (daemon(0,0) == -1)
    {
         err(1, NULL);
    }

    while (1)
    {
        sleep(15000);
    }
}

