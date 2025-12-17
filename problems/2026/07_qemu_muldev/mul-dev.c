#include "qemu/osdep.h"
#include "qemu/log.h"

#include "hw/misc/mul-dev.h"

#define REG_A   0x8
#define REG_B   0x10
#define REG_RES 0x20

static uint64_t mul_dev_read(void *opaque, hwaddr addr, unsigned len)
{
    MulDev *dev = opaque;

    switch (addr) {
    case REG_RES:
        return dev->a * dev->b;
    default:
        return 0;
    }
}

static void mul_dev_write(void *opaque, hwaddr addr, uint64_t val,
                          unsigned len)
{
    MulDev *dev = opaque;

    switch (addr) {
    case REG_A:
        dev->a = val;
        break;
    case REG_B:
        dev->b = val;
        break;
    default:
        break;
    }
}

static const MemoryRegionOps mul_dev_ops = {
    .read       = mul_dev_read,
    .write      = mul_dev_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
};

static void mul_dev_init(Object *obj)
{
    MulDev *s = MUL_DEV(obj);
    SysBusDevice *sbd = SYS_BUS_DEVICE(obj);

    qemu_log("%s: enter\n", __func__);

    s->a = 0;
    s->b = 0;

    memory_region_init_io(&s->iomem, OBJECT(s), &mul_dev_ops, s,
                          TYPE_MUL_DEV, MUL_DEV_SIZE);
    sysbus_init_mmio(sbd, &s->iomem);
}

static void mul_dev_class_init(ObjectClass *klass, void *data)
{
    DeviceClass *dc = DEVICE_CLASS(klass);
    dc->desc = TYPE_MUL_DEV;
    set_bit(DEVICE_CATEGORY_MISC, dc->categories);
}

static const TypeInfo mul_dev_info = {
    .name          = TYPE_MUL_DEV,
    .parent        = TYPE_SYS_BUS_DEVICE,
    .instance_size = sizeof(MulDev),
    .instance_init = mul_dev_init,
    .class_init    = mul_dev_class_init,
};

static void mul_dev_register_types(void)
{
    type_register_static(&mul_dev_info);
}

type_init(mul_dev_register_types)
