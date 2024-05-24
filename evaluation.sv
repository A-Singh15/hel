`timescale 1ns/1ps

class coverage_class;
    real ME_Coverage;
    virtual mem_est_if mem_vif;
    mailbox mon2cov;
    transaction_class trans;

    covergroup ME_coverage;
        coverpoint trans.BestDist;
        coverpoint trans.Expected_motionX {
            bins neg_vals[] = {[-8:-1]};
            bins zero_val = {0};
            bins pos_vals[] = {[1:7]};
        }
        coverpoint trans.Expected_motionY {
            bins neg_vals[] = {[-8:-1]};
            bins zero_val = {0};
            bins pos_vals[] = {[1:7]};
        }
        coverpoint trans.motionX {
            bins neg_vals[] = {[-8:-1]};
            bins zero_val = {0};
            bins pos_vals[] = {[1:7]};
        }
        coverpoint trans.motionY {
            bins neg_vals[] = {[-8:-1]};
            bins zero_val = {0};
            bins pos_vals[] = {[1:7]};
        }
        cross trans.Expected_motionX, trans.Expected_motionY;
        cross trans.motionX, trans.motionY;
    endgroup

    function new(virtual mem_est_if mem_vif, mailbox mon2cov);
        this.mem_vif = mem_vif;
        this.mon2cov = mon2cov;
        ME_coverage = new();
    endfunction

    task sample_coverage();
        forever begin
            mon2cov.get(trans);
            ME_coverage.sample();
            ME_Coverage = ME_coverage.get_coverage();
        end
    endtask
endclass
