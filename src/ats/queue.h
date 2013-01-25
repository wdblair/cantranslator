/*** 
     The interface that allows C programs to utilize queues.
     
     This shows getting to ATS from C can be tricky.
***/
#ifndef _ATS_QUEUE_H_
#define _ATS_QUEUE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

#define QUEUE_TYPE(type) queue_##type##_t

#define QUEUE_DECLARE(type, max_length)                         \
                                                                \
  typedef struct {                                              \
    int head;                                                   \
    int tail;                                                   \
    int max;                                                    \
    type elements[max_length];                                  \
  } queue_##type##_t;                                           \
                                                                \
  extern void queue_init_01931_##type (void *);                 \
                                                                \
  extern bool queue_push_01928_##type (void *, type);           \
                                                                \
  extern type queue_pop_01929_##type (void *);                  \
                                                                \
  extern type queue_peek_01930_##type (void *);                 \
                                                                \
  extern bool queue_full_01934_##type (void *);                 \
                                                                \
  extern int queue_length_01932_##type (void *) ;               \
                                                                \
  extern int queue_available_01933_##type (void *) ;            \
  extern bool queue_full_01934_##type(void *) ;                 \
  extern bool queue_empty_01935_##type (void *) ;               \
  extern void queue_snapshot_01936_##type (void *, void *) ;    \

#define QUEUE_PUSH(type, queue, value) queue_push_01928_##type(queue, value)
#define QUEUE_POP(type, queue) queue_pop_01929_##type ((void*)queue)
#define QUEUE_PEEK(type, queue) queue_peek_01930_##type ((void*)queue)
#define QUEUE_INIT(type, queue) queue_init_01931_##type ((void*)queue)
#define QUEUE_LENGTH(type, queue) queue_length_01932_##type ((void*)queue) 
#define QUEUE_AVAILABLE(type, queue) queue_available_01933_##type((void*)queue)
#define QUEUE_FULL(type, queue) queue_full_01934_##type((void*)queue)  
#define QUEUE_EMPTY(type, queue) queue_empty_01935_##type((void*)queue)
#define QUEUE_SNAPSHOT(type, queue, snapshot) queue_snapshot_01936_##type((void*)queue, (void*)snapshot)


#endif
