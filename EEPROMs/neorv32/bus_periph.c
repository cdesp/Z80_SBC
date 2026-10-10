#include "bus_periph.h"

// -----------------------------------------------------------------------------
// Bus ownership. Nested calls are allowed: only the outermost acquire requests
// the bus and only the outermost release gives it back (after the UART is idle).
// -----------------------------------------------------------------------------
static uint8_t bus_depth = 0;

void bus_acquire(void) {
  if (bus_depth++ == 0) {
    PER_CTRL = PER_CTRL_HOLD;
    while (!(PER_CTRL & PER_CTRL_GRANT));
  }
}

void bus_release(void) {
  if (bus_depth == 0) return;
  if (--bus_depth == 0) {
    while (UART0_TX_BUSY());      // let the last character leave the pin
    PER_CTRL = 0;
  }
}

// -----------------------------------------------------------------------------
// UART
// -----------------------------------------------------------------------------
void bus_uart_init(uint32_t baud) {
  bus_acquire();
  neorv32_uart0_setup(baud, 0);
  bus_release();
}

// -----------------------------------------------------------------------------
// I2C master (byte register accesses at 0x50000000 + reg)
// -----------------------------------------------------------------------------
#define SR_TIP        0x02
#define SR_RXACK      0x80
#define CR_START_WR   0x90
#define CR_WR         0x10
#define CR_WR_STOP    0x50
#define CR_STOP       0x40

static int i2c_wait(void) {                 // 0 = ACK, -1 = NACK or timeout
  uint32_t t = 200000;
  while ((I2C_REG(I2C_SR) & SR_TIP) && --t);
  if (t == 0) return -1;
  return (I2C_REG(I2C_SR) & SR_RXACK) ? -1 : 0;
}

static void i2c_init(void) {
  I2C_REG(I2C_CTR)    = 0x00;
  I2C_REG(I2C_PRERLO) = I2C_PRESCALE & 0xFF;
  I2C_REG(I2C_PRERHI) = (I2C_PRESCALE >> 8) & 0xFF;
  I2C_REG(I2C_CTR)    = 0x80;               // core enable
}

// One transaction: START, address, n data bytes, STOP
int i2c_write_bytes(uint8_t addr7, const uint8_t *d, int n) {
  bus_acquire();
  int res = 0;

  I2C_REG(I2C_TXR) = (uint8_t)(addr7 << 1);
  I2C_REG(I2C_CR)  = CR_START_WR;
  if (i2c_wait()) {
    I2C_REG(I2C_CR) = CR_STOP;
    res = -1;
  } else {
    for (int i = 0; i < n; i++) {
      I2C_REG(I2C_TXR) = d[i];
      I2C_REG(I2C_CR)  = (i == n - 1) ? CR_WR_STOP : CR_WR;
      if (i2c_wait()) {
        I2C_REG(I2C_CR) = CR_STOP;
        res = -1;
        break;
      }
    }
  }

  bus_release();
  return res;
}

// -----------------------------------------------------------------------------
// PCF8574 LCD: P0=RS P1=RW P2=E P3=BL P4..P7=D4..D7
// -----------------------------------------------------------------------------
#define LCD_RS         0x01
#define LCD_ENABLE     0x04
#define LCD_BACKLIGHT  0x08

// init-sequence nibble: E high, then E low
static void lcd_write_nibble(uint8_t nibble, uint8_t rs) {
  uint8_t d = (nibble & 0xF0) | (rs ? LCD_RS : 0) | LCD_BACKLIGHT;
  uint8_t b[2] = { (uint8_t)(d | LCD_ENABLE), (uint8_t)(d & ~LCD_ENABLE) };
  i2c_write_bytes(I2C_LCD_ADDR, b, 2);
}

// full byte = 4 PCF8574 writes in one I2C transaction
static void lcd_send_byte(uint8_t v, uint8_t rs) {
  uint8_t m  = (rs ? LCD_RS : 0) | LCD_BACKLIGHT;
  uint8_t hi = (v & 0xF0) | m;
  uint8_t lo = ((v << 4) & 0xF0) | m;
  uint8_t b[4] = { (uint8_t)(hi | LCD_ENABLE), hi, (uint8_t)(lo | LCD_ENABLE), lo };
  i2c_write_bytes(I2C_LCD_ADDR, b, 4);
}

static uint8_t lcd_cols = 16;
static uint8_t lcd_rows = 2;

void lcd_init(uint8_t cols, uint8_t rows) {
  lcd_cols = cols;
  lcd_rows = rows;
  bus_acquire();
#if I2C_DO_INIT
  i2c_init();
#endif
  neorv32_cpu_delay_ms(50);                         // power-up delay
  lcd_write_nibble(0x30, 0); neorv32_cpu_delay_ms(5);
  lcd_write_nibble(0x30, 0); neorv32_cpu_delay_ms(1);
  lcd_write_nibble(0x30, 0); neorv32_cpu_delay_ms(1);
  lcd_write_nibble(0x20, 0); neorv32_cpu_delay_ms(1);   // 4-bit mode
  lcd_send_byte(0x28, 0);                           // 2 lines, 5x8
  lcd_send_byte(0x0C, 0);                           // display on, cursor off
  lcd_send_byte(0x06, 0);                           // entry mode: increment
  lcd_send_byte(0x01, 0); neorv32_cpu_delay_ms(3);  // clear
  bus_release();
}

void lcd_cmd(uint8_t cmd) {
  bus_acquire();
  lcd_send_byte(cmd, 0);
  if (cmd <= 0x03) neorv32_cpu_delay_ms(3);         // clear / home are slow
  bus_release();
}

void lcd_clear(void) {
  lcd_cmd(0x01);
}

void lcd_set_cursor(uint8_t col, uint8_t row) {
  if (row >= lcd_rows) row = lcd_rows - 1;
  if (col >= lcd_cols) col = lcd_cols - 1;
  // HD44780 DDRAM row starts: rows 2 and 3 continue rows 0 and 1
  uint8_t base;
  switch (row) {
    case 0:  base = 0x00;            break;
    case 1:  base = 0x40;            break;
    case 2:  base = 0x00 + lcd_cols; break;
    default: base = 0x40 + lcd_cols; break;
  }
  lcd_cmd(0x80 | (base + col));
}

void lcd_print_str(const char *s) {
  bus_acquire();
  while (*s) lcd_send_byte((uint8_t)*s++, 1);
  bus_release();
}
