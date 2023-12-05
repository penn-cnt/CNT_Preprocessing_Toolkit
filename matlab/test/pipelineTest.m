%% Test Class Definition
classdef pipelineTest < matlab.unittest.TestCase

    %% Test Method Block
    methods (Test)
        % includes unit test functions
        function testPipeline(testCase)   
            % This part test for wrong input types
            % see https://www.mathworks.com/help/matlab/matlab_prog/types-of-qualifications.html
            % for qualification method
            addpath(genpath('./..'))
            session = iEEGPreprocess();
            runtests("authTest");
            session.login();
            data = session.download_data('I001_P034_D01', 1000,1015);
            assert(session.num_data == 1)
            assert(data.index == 1)
            
            data.clean_labels()
            data.find_nonieeg()
            data.find_bad_chs()
            nchs = size(data.data,2);
            data.reject_nonieeg()
            assert(sum(data.nonieeg) + size(data.data,2) == nchs)
            nchs = size(data.data,2);
            data.reject_artifact()
            assert(sum(data.bad) + size(data.data,2) == nchs)
            data.bandpass_filter()
            data.notch_filter()
            data.filter()
            data.reverse()
            data.car()
            assert(~isempty(data.ref_chnames))
            data.reverse()
            data.reref("car")
            data.reverse()
            data.reref("bipolar")
            data.reverse()
            data.laplacian("elec_locs.csv")
            assert(~isempty(data.locs))
            f = data.plot();
            close all
            data.pre_whiten()
            data.reverse() % there's an issue that cannot calculates bandpower after pre-whitening
            data.line_length()
            assert(~any(isnan(data.ll)))
            data.bandpower()
            assert(~any(isnan(data.power(1).power)))
            data.pearson(false)
            data.pearson()
            data.squared_pearson()
            data.cross_corr()
            data.coherence()
            assert(isequal(fieldnames(data.conn),{'pearson','squared_pearson','cross_corr','coh'}'));
            data.plv()
            data.rela_entropy()
            data.connectivity({'pearson', 'plv'})
            fig = data.conn_heatmap("coh", "delta");
            close all
            data.save([], false)
            session.load_data(".", [], false)
            assert(session.num_data == 2)
            session.remove_data(2)
            assert(session.num_data == 1)
            session.save("session1", false)
            session.load_data("session1.mat", [], false)
            assert(session.num_data == 2)
            session.load_data("session1.mat", true, false)
            assert(session.num_data == 1)
            delete session1.mat
            delete(strcat("I001_P034_D01_" + num2str(1000) + "_" + num2str(1015) + ".mat"))
            selec = {'Grid1','Grid2','Micro1','Micro2','Strip1','Strip2'};
            data = session.download_data('I001_P034_D01', 10000,10015,selec);
            assert(size(data.data,2) == length(selec));
            data.bipolar()
            assert(size(data.data,2) == 3)
            assert(data.nchs == 3)
            assert(length(data.ch_names) == 3)
            assert(length(data.ref_chnames) == 3)
            data.reverse()
            assert(size(data.data,2) == length(selec));
            assert(data.nchs == length(selec))
            assert(length(data.ch_names) == length(selec))
        end
    end
end