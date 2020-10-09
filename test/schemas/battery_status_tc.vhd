library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TestCase_pkg.all;
use work.Stream_pkg.all;
use work.ClockGen_pkg.all;
use work.StreamSource_pkg.all;
use work.StreamSink_pkg.all;
use work.Json_pkg.all;
use work.test_util_pkg.all;
use work.TestCase_pkg.all;

entity battery_status_tc is
end battery_status_tc;

architecture test_case of battery_status_tc is

  signal clk              : std_logic;
  signal reset            : std_logic;


  signal in_valid         : std_logic;
  signal in_ready         : std_logic;
  signal in_dvalid        : std_logic;
  signal in_last          : std_logic;
  signal in_data          : std_logic_vector(63 downto 0);
  signal in_count         : std_logic_vector(3 downto 0);
  signal in_strb          : std_logic_vector(7 downto 0);
  signal in_endi          : std_logic_vector(3 downto 0);

  signal adv_last         : std_logic_vector(15 downto 0);


  signal kv_ready        : std_logic;
  signal kv_valid        : std_logic;
  signal kv_data         : std_logic_vector(63 downto 0);
  signal kv_tag          : std_logic_vector(7 downto 0);
  signal kv_stai         : std_logic_vector(2 downto 0);
  signal kv_endi         : std_logic_vector(2 downto 0);
  signal kv_strb         : std_logic_vector(7 downto 0);
  signal kv_empty        : std_logic_vector(7 downto 0);
  signal kv_last         : std_logic_vector(23 downto 0);

  signal array_ready        : std_logic;
  signal array_valid        : std_logic;
  signal array_data         : std_logic_vector(63 downto 0);
  signal array_stai         : std_logic_vector(2 downto 0);
  signal array_endi         : std_logic_vector(2 downto 0);
  signal array_strb         : std_logic_vector(7 downto 0);
  signal array_empty        : std_logic_vector(7 downto 0);
  signal array_last         : std_logic_vector(31 downto 0);

  signal conv_ready        : std_logic;
  signal conv_valid        : std_logic;
  signal conv_data         : std_logic_vector(63 downto 0);
  signal conv_stai         : std_logic_vector(2 downto 0);
  signal conv_endi         : std_logic_vector(2 downto 0);
  signal conv_strb         : std_logic_vector(7 downto 0);
  signal conv_empty        : std_logic_vector(7 downto 0);
  signal conv_last         : std_logic_vector(31 downto 0);
  

  signal out_ready       : std_logic;
  signal out_valid       : std_logic;
  signal out_empty       : std_logic;
  signal out_dvalid      : std_logic;
  signal out_data        : std_logic_vector(63 downto 0);
  signal out_last        : std_logic_vector(2 downto 0);

  
  signal aligned_data    : std_logic_vector(63 downto 0);
  signal out_count       : std_logic_vector(3 downto 0);

  signal out_tag_int     : integer;

  -- signal count_ready     : std_logic;
  -- signal count_valid     : std_logic;
  -- signal count           : std_logic_vector(7 downto 0);



begin

  clkgen: ClockGen_mdl
    port map (
      clk                       => clk,
      reset                     => reset
    );

  in_source: StreamSource_mdl
    generic map (
      NAME                      => "a",
      ELEMENT_WIDTH             => 8,
      COUNT_MAX                 => 8,
      COUNT_WIDTH               => 4
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      valid                     => in_valid,
      ready                     => in_ready,
      dvalid                    => in_dvalid,
      last                      => in_last,
      data                      => in_data,
      count                     => in_count
    );

    in_strb <= element_mask(in_count, in_dvalid, 8); 
    in_endi <= std_logic_vector(unsigned(in_count) - 1);

    adv_last <= std_logic_vector(shift_left(unsigned'("0000000" & in_last), to_integer(unsigned(in_endi))))  & "00000000";

    
    record_parser_i: JsonRecordParser
    generic map (
      ELEMENTS_PER_TRANSFER     => 8,
      OUTER_NESTING_LEVEL       => 1,
      INNER_NESTING_LEVEL       => 1
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      in_valid                  => in_valid,
      in_ready                  => in_ready,
      in_data.data              => in_data,
      in_data.comm              => ENABLE,
      in_strb                   => in_strb,
      in_last                   => adv_last,
      out_data.data             => kv_data,
      out_data.tag              => kv_tag,
      out_stai                  => kv_stai,
      out_endi                  => kv_endi,
      out_ready                 => kv_ready,
      out_valid                 => kv_valid,
      out_strb                  => kv_strb,
      out_last                  => kv_last,
      out_empty                 => kv_empty
    );



    array_parser_i: JsonArrayParser
    generic map (
      ELEMENTS_PER_TRANSFER     => 8,
      OUTER_NESTING_LEVEL       => 2,
      INNER_NESTING_LEVEL       => 0,
      ELEMENT_COUNTER_BW        => 8
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      in_valid                  => kv_valid,
      in_ready                  => kv_ready,
      in_data.data              => kv_data,
      in_data.comm              => ENABLE,
      in_last                   => kv_last,
      in_strb                   => kv_strb,
      in_empty                  => kv_empty,
      out_data                  => array_data,
      out_valid                 => array_valid,
      out_ready                 => array_ready,
      out_last                  => array_last,
      out_stai                  => array_stai,
      out_endi                  => array_endi,
      out_strb                  => array_strb,
      out_empty                 => array_empty
      -- out_count_ready           => count_ready,
      -- out_count_valid           => count_valid,
      -- out_count_data            => count
    );

    -- converter: c8_to_c7
    -- generic map (
    --   data_width                => 8,
    --   ELEMENTS_PER_TRANSFER     => 8,
    --   DIMENSIONALITY            => 4
    -- )
    -- port map (
    --   clk                       => clk,
    --   reset                     => reset,
    --   in_valid                  => array_valid,
    --   in_ready                  => array_ready,
    --   in_data                   => array_data,
    --   in_last                   => array_last,
    --   in_strb                   => array_strb,
    --   in_empty                  => array_empty,
    --   out_valid                 => conv_valid,
    --   out_ready                 => conv_ready,
    --   out_data                  => conv_data,
    --   out_last                  => conv_last,
    --   out_strb                  => conv_strb,
    --   out_empty                 => conv_empty
    -- );


    intparser_i: IntParser
    generic map (
      ELEMENTS_PER_TRANSFER     => 8,
      NESTING_LEVEL             => 3,
      BITWIDTH                  => 64
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      in_valid                  => array_valid,
      in_ready                  => array_ready,
      in_data.data              => array_data,
      in_data.comm              => ENABLE,
      in_last                   => array_last,
      in_strb                   => array_strb,
      in_empty                  => array_empty,
      out_data                  => out_data,
      out_valid                 => out_valid,
      out_ready                 => out_ready,
      out_last                  => out_last,
      out_empty                 => out_empty
    );

    --out_ready <= '1';
    --out_tag_int <= kv_tag_t'POS(out_tag);
    out_dvalid <= not out_empty;

    out_sink: StreamSink_mdl
    generic map (
      NAME                      => "b",
      ELEMENT_WIDTH             => 64,
      COUNT_MAX                 => 1,
      COUNT_WIDTH               => 1
    )
    port map (
      clk                       => clk,
      reset                     => reset,
      valid                     => out_valid,
      ready                     => out_ready,
      data                      => out_data,
      dvalid                    => out_dvalid
    );

    -- count_sink: StreamSink_mdl
    -- generic map (
    --   NAME                      => "c",
    --   ELEMENT_WIDTH             => 8,
    --   COUNT_MAX                 => 1,
    --   COUNT_WIDTH               => 1
    -- )
    -- port map (
    --   clk                       => clk,
    --   reset                     => reset,
    --   ready                     => count_ready,
    --   valid                     => count_valid,
    --   data                      => count
    -- );
    

  random_tc: process is
    variable a        : streamsource_type;
    variable b        : streamsink_type;
    --variable c        : streamsink_type;

  begin
    tc_open("JsonRecordParser", "test");
    a.initialize("a");
    b.initialize("b");
    --c.initialize("c");

    a.push_str("{""values"" : [11 , 22]} {""valuessss"": [33 , 44]}{""values"" : [55 , 66]}{""values"" : [77 , 88, 99 ]}");
    a.transmit;
    b.unblock;
    --c.unblock;

    tc_wait_for(2 us);

    tc_check(b.pq_ready, true);
    tc_check(b.cq_get_d_nat, 11, "11");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    tc_check(b.cq_get_d_nat, 22, "22");
    --tc_check(c.cq_get_d_nat, 2, "count: 2");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    --c.cq_next;
    tc_check(b.cq_get_d_nat, 33, "33");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    tc_check(b.cq_get_d_nat, 44, "44");
    b.cq_next;
    --tc_check(c.cq_get_d_nat, 2, "count: 2");
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    --c.cq_next;
    tc_check(b.cq_get_d_nat, 55, "55");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    tc_check(b.cq_get_d_nat, 66, "66");
    b.cq_next;
    --tc_check(c.cq_get_d_nat, 2, "count: 2");
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    --c.cq_next;
    tc_check(b.cq_get_d_nat, 77, "77");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    tc_check(b.cq_get_d_nat, 88, "88");
    b.cq_next;
    while not b.cq_get_dvalid loop
      b.cq_next;
    end loop;
    tc_check(b.cq_get_d_nat, 99, "99");
    --tc_check(c.cq_get_d_nat, 3, "count: 3");

    tc_pass;
    wait;
  end process;

end test_case;