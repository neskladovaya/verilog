#ifndef HW_MISC_MUL_DEV_H
#define HW_MISC_MUL_DEV_H

#include "hw/sysbus.h"
#include "exec/memory.h"
#include "qom/object.h"

#define MUL_DEV_SIZE 0x1000
#define TYPE_MUL_DEV "mul-dev"

OBJECT_DECLARE_SIMPLE_TYPE(MulDev, MUL_DEV)

struct MulDev {
    SysBusDevice parent_obj;
    MemoryRegion iomem;

    uint64_t a;
    uint64_t b;
};

#endif /* HW_MISC_MUL_DEV_H */
