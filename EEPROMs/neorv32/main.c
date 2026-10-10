#include "neorv32.h"
#include <stdint.h>
#include "bus_periph.h"

// Region C: external 8-bit SRAM = 0x40000000 - 0x400FFFFF (1 MB)
#define SRAM_BASE_ADDR   ((volatile uint8_t *) 0x40000000UL)
#define SRAM_BLOCK_SIZE  1024   // 1 KB sample block

int main(void) {
  // 1. UART0 for debug output
  bus_uart_init(115200);
  bus_uart0_printf("\n========================================\n");
  bus_uart0_printf("  NEORV32 External Bus & I2C Demo\n");
  bus_uart0_printf("========================================\n");

  // 2. LCD over the shared I2C
  bus_uart0_printf("[I2C] Initializing LCD...\n");
  lcd_init(20, 4);                 // use lcd_init(16, 2) for a 16x2 display
  lcd_set_cursor(0, 0);
  lcd_print_str("NEORV32 Engine");
  lcd_set_cursor(0, 1);
  lcd_print_str("Reading SRAM...");

  // 3. Read external SRAM and process
  bus_uart0_printf("[SRAM] Reading %d bytes at 0x%x...\n",
                   (int)SRAM_BLOCK_SIZE, (unsigned int)(uintptr_t)SRAM_BASE_ADDR);

  uint32_t checksum = 0;
  uint8_t  peak_value = 0;
  for (uint32_t i = 0; i < SRAM_BLOCK_SIZE; i++) {
    uint8_t sample = SRAM_BASE_ADDR[i];
    checksum += sample;
    if (sample > peak_value) peak_value = sample;
  }

  bus_uart0_printf("[MATH] Processing complete.\n");
  bus_uart0_printf("       -> Checksum: 0x%x\n", (unsigned int)checksum);
  bus_uart0_printf("       -> Peak Val: %d\n", (int)peak_value);

  // 4. GPIO output
  uint32_t gpio_val = peak_value & 0xFF;
  neorv32_gpio_port_set(gpio_val);
  bus_uart0_printf("[GPIO] Output port set to: 0x%x\n", (unsigned int)gpio_val);

  // 5. Update LCD
  //lcd_clear();
  lcd_set_cursor(0, 2);
  lcd_print_str("SRAM Processed!");
  lcd_set_cursor(0, 3);
  lcd_print_str(checksum > 0 ? "Status: PASS" : "Status: EMPTY");

  // 6. Heartbeat on GPIO pin 0
  bus_uart0_printf("[SYS] Running heartbeat loop...\n");
  while (1) {
    neorv32_gpio_pin_set(0);
    neorv32_cpu_delay_ms(500);
    neorv32_gpio_pin_clr(0);
    neorv32_cpu_delay_ms(500);
  }

  return 0;
}
