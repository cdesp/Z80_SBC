#ifndef BUS_PERIPH_H
#define BUS_PERIPH_H

#include <stdint.h>
#include "neorv32.h"

// -----------------------------------------------------------------------------
// Shared peripheral region 0x50000000 (handled by cpu_top_level.vhd)
//   0x50000000..07 : Gowin I2C master registers (BYTE accesses only!)
//   0x50000010     : control reg  write bit0 = request/hold RV32Master
//                                 read  bit0 = hold, bit1 = RV32Grant
// -----------------------------------------------------------------------------
#define PER_BASE        0x50000000UL
#define PER_CTRL        (*(volatile uint8_t *)(PER_BASE + 0x10))
#define PER_CTRL_HOLD   0x01
#define PER_CTRL_GRANT  0x02

// Gowin / OpenCores-style I2C master registers (check against your IP doc)
#define I2C_REG(r)      (*(volatile uint8_t *)(PER_BASE + (r)))
#define I2C_PRERLO      0
#define I2C_PRERHI      1
#define I2C_CTR         2
#define I2C_TXR         3
#define I2C_RXR         3
#define I2C_CR          4
#define I2C_SR          4

// Settings (override before including if needed)
#ifndef I2C_LCD_ADDR
#define I2C_LCD_ADDR    0x27     // 7-bit address (0x27 or 0x3F typically)
#endif
#ifndef I2C_DO_INIT
#define I2C_DO_INIT     1        // 0 if the Z80 side already configures the IP
#endif
#ifndef I2C_PRESCALE
#define I2C_PRESCALE    99       // (IP clock / (5 * 100 kHz)) - 1
#endif

// TX busy helper: change this line if your NEORV32 version names it differently
#ifndef UART0_TX_BUSY
#define UART0_TX_BUSY() neorv32_uart0_tx_busy()
#endif

// ---- Bus ownership (nestable) ----
void bus_acquire(void);
void bus_release(void);

// ---- UART (on-core UART0, only reaches the pin while the bus is granted) ----
void bus_uart_init(uint32_t baud);
#define bus_uart0_printf(...) \
    do { bus_acquire(); neorv32_uart0_printf(__VA_ARGS__); bus_release(); } while (0)

// ---- I2C ----
int  i2c_write_bytes(uint8_t addr7, const uint8_t *data, int n);   // 0 = OK, -1 = NACK/timeout

// ---- PCF8574 LCD (HD44780, 4-bit) ----
void lcd_init(uint8_t cols, uint8_t rows);   // e.g. lcd_init(16, 2) or lcd_init(20, 4)
void lcd_cmd(uint8_t cmd);
void lcd_clear(void);
void lcd_set_cursor(uint8_t col, uint8_t row);
void lcd_print_str(const char *s);

#endif
