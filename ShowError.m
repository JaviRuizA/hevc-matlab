function ShowError( ME )
errorMessage = sprintf('  Error in function %s() at line %d.\n  Error Message:\n  %s', ...
    ME.stack(1).name, ME.stack(1).line, ME.message);
fprintf('******************************************************\n');
fprintf('%s', errorMessage);
fprintf('******************************************************\n');
end

