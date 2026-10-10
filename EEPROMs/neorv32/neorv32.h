#ifndef NEORV32_H
#define NEORV32_H

#include <stdint.h>

#define NEORV32_UART0_BASE 0xFFF50000UL
#define NEORV32_GPIO_BASE  0xFFFC0000UL

#define UART0_CTRL (*(volatile uint32_t *)(NEORV32_UART0_BASE + 0x00))
#define UART0_DATA (*(volatile uint32_t *)(NEORV32_UART0_BASE + 0x04))

#define UART_CTRL_EN        0
#define UART_CTRL_BAUD_LSB  6    // bits 15:6 (prescaler in 5:3)
#define UART_CTRL_TX_NFULL  19   // 1 = TX FIFO has space
#define UART_CTRL_TX_BUSY   31   // 1 = shifting out

// GPIO Registers
#define NEORV32_GPIO_OUTPUT (*(volatile uint32_t *)(NEORV32_GPIO_BASE + 0x04))


// CPU Delay (~50 MHz clock)
static inline void neorv32_cpu_delay_ms(uint32_t ms) {
  volatile uint32_t count = ms * 5000;
  while (count--) {
    asm volatile("nop");
  }
}

// GPIO Drivers
static inline void neorv32_gpio_port_set(uint32_t val) {
  NEORV32_GPIO_OUTPUT = val;
}

static inline void neorv32_gpio_pin_set(int pin) {
  NEORV32_GPIO_OUTPUT |= (1U << pin);
}

static inline void neorv32_gpio_pin_clr(int pin) {
  NEORV32_GPIO_OUTPUT &= ~(1U << pin);
}

// UART0 Drivers
static inline void neorv32_uart0_setup(uint32_t baud, uint32_t flags) {
  (void)flags;
  uint32_t div = (50000000UL / (2 * baud)) - 1;       // 216 for 115200
  UART0_CTRL = (1U << UART_CTRL_EN) | (div << UART_CTRL_BAUD_LSB);
}
static inline int neorv32_uart0_tx_busy(void) {
  return (UART0_CTRL >> UART_CTRL_TX_BUSY) & 1;
}
static inline void neorv32_uart0_putc(char c) {
  while (!((UART0_CTRL >> UART_CTRL_TX_NFULL) & 1));
  UART0_DATA = (uint32_t)(uint8_t)c;
}
static inline void neorv32_uart0_puts(const char *s) {
  while (*s) { if (*s == '\n') neorv32_uart0_putc('\r'); neorv32_uart0_putc(*s++); }
}

static inline void neorv32_uart0_print(const char *s) {
  while (*s) {
    if (*s == '\n') neorv32_uart0_putc('\r');
    neorv32_uart0_putc(*s++);
  }
}

static inline void neorv32_uart0_printf(const char *fmt, ...) {
  neorv32_uart0_print(fmt);
}

#endif // NEORV32_H