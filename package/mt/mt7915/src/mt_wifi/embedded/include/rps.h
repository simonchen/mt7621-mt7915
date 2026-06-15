#ifndef __MTK_RPS__
#define __MTK_RPS__

// simonchen - RPS Target CPU
#ifndef MTK_NAPI_ID
#define MTK_NAPI_ID 0xFFFF7915
#endif
#define POLL_PKTS_64 64
#define POLL_PKTS_256 256
#define POLL_PKTS_512 512
#define POLL_PKTS_1024 1024
#define GET_TARGET_CPU_HASH(roller, net_dev, pkts) ({          \
    u32 __hash_val = 0;                                         \
    struct net_device *__dev = (struct net_device *)(net_dev);  \
    \
    if (likely(__dev && __dev->_rx)) {                          \
        struct rps_map *__map = __dev->_rx->rps_map;            \
        u32 __ep_ro = (__map) ? __map->len : 0;                \
        \
        if (__ep_ro < 2) {                                      \
            __ep_ro = 2;                                        \
        }                                                       \
        \
        u32 __mask  = (__ep_ro == 4 || __ep_ro == 3) ? 3  : 1;  \
        u32 __shift = (__ep_ro == 4 || __ep_ro == 3) ? 30 : 31; \
        \
        __hash_val = ((__this_cpu_read(roller) >> (31 - __builtin_clz(pkts))) & __mask) << __shift; \
        __this_cpu_add(roller, 1);                      \
    }           \
    __hash_val;                                                 \
})

#endif /* __MTK_RPS__ */
