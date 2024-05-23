
module scoreboard;
  task compare(input transaction exp, input transaction act);
    // Implement comparison logic
    if (exp.data !== act.data) begin
      $display("Mismatch: Expected %0h, Got %0h", exp.data, act.data);
    end
  endtask
endmodule
